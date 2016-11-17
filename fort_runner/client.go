package main

import (
	"github.com/coldog/ci-minion/minion"
	"github.com/parnurzeal/gorequest"
	"github.com/dgrijalva/jwt-go"
	"fmt"
	"encoding/json"
	"errors"
)

var ErrNotFound = errors.New("no jobs found")

type JobResponse struct {
	Job *minion.Job `json:"job"`
}

func NewClient(api string) *Client {
	return &Client{API: api}
}

type Client struct {
	worker string
	API string
	token string
	secret string
}

func (c *Client) SetWorker(worker string) {
	c.worker = worker

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{"worker": c.worker})
	tokenString, err := token.SignedString([]byte(c.secret))
	if err != nil {
		panic(err)
	}

	c.token = fmt.Sprintf("Bearer %s", tokenString)
}

func (c *Client) SetSecret(secret string) {
	c.secret = secret
}

func (c *Client) Dequeue() (*minion.Job, error) {
	resp, _, errs := gorequest.New().
		Get(c.API + "/worker/jobs/dequeue").
		Set("Authorization", c.token).
		End()

	if err := reqErr(resp, errs); err != nil {
		return nil, err
	}

	res := &JobResponse{}
	json.NewDecoder(resp.Body).Decode(res)

	if res.Job == nil {
		return nil, ErrNotFound
	}

	return res.Job, nil
}

func (c *Client) Reject(id string) error {
	resp, _, errs := gorequest.New().
		Post(c.API + "/worker/jobs/" + id + "/reject").
		Set("Authorization", c.token).
		End()

	return reqErr(resp, errs)
}

func (c *Client) UpdateStatus(id string, status string) error {
	resp, _, errs := gorequest.New().
		Post(c.API + "/worker/jobs/" + id + "/status").
		Set("Authorization", c.token).
		Param("status", status).
		End()

	return reqErr(resp, errs)
}

func reqErr(resp gorequest.Response, errs []error) error {
	if len(errs) > 0 {
		return errs[0]
	}

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf(resp.Status)
	}
	return nil
}
