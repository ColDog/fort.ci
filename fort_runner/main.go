package main

import (
	"github.com/coldog/ci-minion/minion"
	"flag"
	"strings"
	"log"
	"time"
)

func main() {
	workerUrlFlag := flag.String("address", "http://localhost:3001", "Address to publish")
	apiAddrFlag := flag.String("api", "http://localhost:3000", "Main api address")
	bindFlag := flag.String("bind", ":3001", "Address to bind to")
	secretFlag := flag.String("secret", "secret", "Secret key")
	executorsFlag := flag.Int("executors", 1, "Parallel executors")
	waitFlag := flag.Duration("poll-interval", 20 * time.Second, "Polling interval")

	flag.Parse()

	client := NewClient(*apiAddrFlag)
	client.SetSecret(*secretFlag)
	client.SetWorker(strings.Split(*workerUrlFlag, "://")[1])

	exec := minion.NewExecutor()

	exec.WaitDur = *waitFlag
	exec.MaxSize = *executorsFlag
	exec.Poller = func(add minion.AddJob) {
		job, err := client.Dequeue()

		if err != nil {
			log.Printf("Error dequeueing job: %v", err)
			return
		}

		err = add(job)
		if err != nil {
			log.Printf("Error adding job: %v", err)
			client.Reject(job.ID)
		}
	}

	exec.OnFinish = func(r *minion.Run) {
		status := "COMPLETED"
		if r.Failure != nil {
			status = "FAILED"
		}

		err := client.UpdateStatus(r.Job.ID, status)
		if err != nil {
			log.Printf("Error updating job: %v", err)
		}
		log.Printf("Update job %s with status %s", r.Job.ID, status)
	}

	exec.Start()
	exec.Serve(*bindFlag)
}
