package main

import (
	"log"
	"os"
	"path/filepath"
	"text/template"
)

type User struct {
	Passwd             string
	SSH_authorized_key string
}

func main() {
	home_dir, homedir_err := os.UserHomeDir()
	if homedir_err != nil {
		log.Fatalf("Could not determine home directory! %v", homedir_err)
		return
	}
	ssh_pubkey := filepath.Join(home_dir, ".ssh/id_rsa.pub")
	ssh_key, ssh_key_err := os.ReadFile(ssh_pubkey)
	if ssh_key_err != nil {
		log.Fatalf("Could not read the SSH public key! %v", ssh_key_err)
		return
	}
	user := User{Passwd: "test", SSH_authorized_key: string(ssh_key)}
	t1 := template.New("t1")
	raw, err := os.ReadFile(os.Args[1])
	if err != nil {
		log.Fatalf("Could not read input %v", err)
		return
	}
	str := string(raw)
	println(str)
	t1, parse_err := t1.Parse(str)
	if parse_err != nil {
		log.Fatalf("Could not parse template! %v", parse_err)
		return
	}
	exec_err := t1.Execute(os.Stdout, user)
	if exec_err != nil {
		log.Fatalf("Could not execute template! %v", exec_err)
	}
	println("Foo")
}
