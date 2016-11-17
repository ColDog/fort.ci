package minion

import (
	"github.com/julienschmidt/httprouter"
	"encoding/json"
	"fmt"
	"net/http"
	"log"
)

func (e *Executor) handleJobsDelete(w http.ResponseWriter, r *http.Request, rp httprouter.Params) {
	jobKey := rp.ByName("id")

	w.Header().Set("Content-Type", "application/json")

	err := e.Cancel(jobKey)
	if err != nil {
		w.WriteHeader(404)
		w.Write([]byte(fmt.Sprintf(`{"error": "%s"}`, err.Error())))
		return
	}

	w.Write([]byte(`{"status": "OK"}`))
}

func (e *Executor) handleJobsShow(w http.ResponseWriter, r *http.Request, rp httprouter.Params) {
	jobKey := rp.ByName("id")
	data, err := e.Logs(jobKey)

	w.Header().Set("Content-Type", "application/json")

	if err != nil {
		w.WriteHeader(404)
		w.Write([]byte(fmt.Sprintf(`{"error": "%s"}`, err.Error())))
		return
	}

	w.Write(data)
}

func (e *Executor) handleJobsCreate(w http.ResponseWriter, r *http.Request, rp httprouter.Params) {
	decoder := json.NewDecoder(r.Body)

	job := &Job{}
	err := decoder.Decode(job)

	w.Header().Set("Content-Type", "application/json")

	if err == nil {
		err = e.Add(job)
	}

	if err != nil {
		w.WriteHeader(400)
		w.Write([]byte(fmt.Sprintf(`{"error": "%s"}`, err.Error())))
		return
	}


	w.Write([]byte(`{"status": "OK"}`))
}

func (e *Executor) handleJobsList(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
	data, err := json.Marshal(e.List())

	w.Header().Set("Content-Type", "application/json")

	if err != nil {
		w.WriteHeader(404)
		w.Write([]byte(fmt.Sprintf(`{"error": "%s"}`, err.Error())))
		return
	}

	w.Write(data)
}

func (e *Executor) Serve(addr string) {
	router := httprouter.New()
	router.GET("/jobs", e.handleJobsList)
	router.POST("/jobs", e.handleJobsCreate)
	router.GET("/jobs/:id", e.handleJobsShow)
	router.DELETE("/jobs/:id", e.handleJobsDelete)

	log.Println("listening on", addr)
	log.Fatal(http.ListenAndServe(addr, router))
}
