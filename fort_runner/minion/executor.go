package minion

import (
	"io/ioutil"
	"sync"
	"time"
	"encoding/json"
	"fmt"
)

type AddJob func(*Job) error

func NewExecutor() *Executor {
	return &Executor{
		runs: make(map[string]*Run),
		poll: make(chan struct{}),
		quit: make(chan struct{}),
		l:    &sync.RWMutex{},
	}
}

type Executor struct {
	Size     int
	MaxSize  int
	Poller   func(AddJob)
	OnFinish func(*Run)
	WaitDur  time.Duration
	runs     map[string]*Run
	poll     chan struct{}
	quit     chan struct{}
	l        *sync.RWMutex
}

func (e *Executor) List() []string {
	e.l.RLock()
	defer e.l.RUnlock()

	list := make([]string, len(e.runs))
	i := 0
	for key, _ := range e.runs {
		list[i] = key
		i++
	}
	return list
}

func (e *Executor) Cancel(id string) error {
	e.l.RLock()
	run, ok := e.runs[id]
	e.l.RUnlock()

	if !ok {
		 return fmt.Errorf("no job exists")
	}

	run.Quit()
	return nil
}

func (e *Executor) Logs(id string) (data []byte, err error) {
	e.l.RLock()
	run, ok := e.runs[id]
	e.l.RUnlock()

	if ok {
		data, err = json.Marshal(run)
	} else {
		data, err = ioutil.ReadFile(rootDir + "/jobs/" + id + ".json")
	}

	return data, err
}

func (e *Executor) Start() error {
	if e.Poller == nil {
		return fmt.Errorf("'Poller' field is null")
	}
	go e.poller()
	return nil
}

func (e *Executor) Quit() {
	close(e.quit)
}

func (e *Executor) runPoller() {
	if e.Poller != nil {
		e.Poller(e.Add)
	}
}

func (e *Executor) poller() {
	if e.WaitDur == 0 {
		e.WaitDur = 5 * time.Second
	}

	e.runPoller()

	for {
		select {
		case <-time.After(e.WaitDur):
			if e.Size < e.MaxSize {
				e.runPoller()
			}

		case <-e.poll:
			e.runPoller()

		case <-e.quit:
			return
		}
	}
}

func (e *Executor) save(r *Run) error {
	data, err := json.MarshalIndent(r, "", "  ")
	if err != nil {
		panic(err)
	}

	return ioutil.WriteFile("jobs/"+r.Job.ID+".json", data, 0700)
}

func (e *Executor) Add(job *Job) error {

	// ensure that only one repo at a time is being processed
	if job.Repo != nil {
		e.l.RLock()
		for _, run := range e.runs {
			if run.Job.Repo != nil && run.Job.Repo.Name == job.Repo.Name && run.Job.Repo.Owner == job.Repo.Owner {
				e.l.RUnlock()
				return fmt.Errorf("already processing this repo")
			}
		}
		e.l.RUnlock()
	}

	r := NewRunner(job)

	e.l.Lock()
	e.runs[job.ID] = r
	e.Size += 1
	e.l.Unlock()

	go func() {
		r.Run()
		e.save(r)

		e.l.Lock()
		delete(e.runs, job.ID)
		e.Size -= 1
		e.l.Unlock()

		if e.OnFinish != nil {
			e.OnFinish(r)
		}

		if e.Size < e.MaxSize {
			e.poll <- struct{}{}
		}
	}()

	return nil
}
