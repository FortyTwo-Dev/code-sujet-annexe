package main

import (
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"os"

	_ "github.com/lib/pq"
)

type Overview struct {
	OrdersCount   int     `json:"orders_count"`
	Revenue       float64 `json:"revenue"`
	AverageBasket float64 `json:"average_basket"`
}

type TopProduct struct {
	ProductID     int     `json:"product_id"`
	ProductName   string  `json:"product_name"`
	TotalQuantity int     `json:"total_quantity"`
	Revenue       float64 `json:"revenue"`
}

type StatusCount struct {
	Status string `json:"status"`
	Count  int    `json:"count"`
}

func main() {
	db, err := openDB()
	if err != nil {
		log.Fatalf("database connection error: %v", err)
	}
	defer db.Close()

	http.HandleFunc("/health", withCORS(func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]string{
			"status":  "ok",
			"service": "go-api",
		})
	}))

	http.HandleFunc("/stats/overview", withCORS(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
			return
		}

		var result Overview
		query := `
			SELECT
				COUNT(*)::int,
				COALESCE(SUM(total_amount), 0)::float8,
				COALESCE(AVG(total_amount), 0)::float8
			FROM orders
			WHERE status != 'cancelled'
		`
		err := db.QueryRow(query).Scan(&result.OrdersCount, &result.Revenue, &result.AverageBasket)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
			return
		}

		writeJSON(w, http.StatusOK, result)
	}))

	http.HandleFunc("/stats/top-products", withCORS(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
			return
		}

		query := `
			SELECT
				p.id,
				p.name,
				COALESCE(SUM(oi.quantity), 0)::int AS total_quantity,
				COALESCE(SUM(oi.line_total), 0)::float8 AS revenue
			FROM order_items oi
			JOIN products p ON p.id = oi.product_id
			JOIN orders o ON o.id = oi.order_id
			WHERE o.status != 'cancelled'
			GROUP BY p.id, p.name
			ORDER BY total_quantity DESC, revenue DESC
			LIMIT 5
		`

		rows, err := db.Query(query)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
			return
		}
		defer rows.Close()

		var products []TopProduct
		for rows.Next() {
			var p TopProduct
			if err := rows.Scan(&p.ProductID, &p.ProductName, &p.TotalQuantity, &p.Revenue); err != nil {
				writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
				return
			}
			products = append(products, p)
		}

		writeJSON(w, http.StatusOK, products)
	}))

	http.HandleFunc("/stats/status", withCORS(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
			return
		}

		query := `
			SELECT status, COUNT(*)::int
			FROM orders
			GROUP BY status
			ORDER BY status
		`

		rows, err := db.Query(query)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
			return
		}
		defer rows.Close()

		var statuses []StatusCount
		for rows.Next() {
			var s StatusCount
			if err := rows.Scan(&s.Status, &s.Count); err != nil {
				writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
				return
			}
			statuses = append(statuses, s)
		}

		writeJSON(w, http.StatusOK, statuses)
	}))

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Go API listening on :%s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

func openDB() (*sql.DB, error) {
	host := getEnv("DB_HOST", "localhost")
	port := getEnv("DB_PORT", "5432")
	name := getEnv("DB_NAME", "restaurant")
	user := getEnv("DB_USER", "postgres")
	password := getEnv("DB_PASSWORD", "postgres")

	dsn := "host=" + host +
		" port=" + port +
		" dbname=" + name +
		" user=" + user +
		" password=" + password +
		" sslmode=disable"

	return sql.Open("postgres", dsn)
}

func getEnv(key, fallback string) string {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}
	return value
}

func writeJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

func withCORS(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PATCH, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}

		// Si reverse proxy avec /api/go
		if r.URL.Path == "/api/go/health" {
			r.URL.Path = "/health"
		}

		next(w, r)
	}
}
