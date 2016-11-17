package minion

import (
	"sync"
	"testing"
)

func TestExecutors(t *testing.T) {
	j := &Job{
		Name: "list-files",
		ID:   "1.1",
		Sections: []*Section{
			{
				Name:      "list-files",
				Commands:  []string{"ls -a"},
				OnSuccess: []string{"echo 'ok'"},
				OnFailure: []string{"echo 'fail'"},
			},
		},
	}

	e := NewExecutor()
	e.Poller = func() *Job {
		return j
	}
	e.MaxSize = 10

	e.Start()

	wg := &sync.WaitGroup{}
	wg.Add(1)
	e.Add(j, func(r *Run) {
		wg.Done()
	})

	wg.Wait()
}
