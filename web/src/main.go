package main

import (
	"log"
	"net/http"
	"os"
	"time"
)

func main() {
	  http.HandleFunc("/index.html", func(w http.ResponseWriter, r *http.Request) {
		file, err := os.Open("src/index.html")
		if err != nil {
			http.Error(w, "Could not open index.html", http.StatusInternalServerError)
			log.Println("Error opening index.html:", err)
			return
		}
		defer file.Close()

		http.ServeContent(w, r, "src/index.html", time.Time{}, file)
    log.Println("sent index.html")
	})

	// Start the HTTP server on port 8080
	log.Println("Server starting on :8080...")
	err := http.ListenAndServe(":8080", nil); 
  if (err != nil) {
		log.Fatal("Server failed: ", err)
	}
}

