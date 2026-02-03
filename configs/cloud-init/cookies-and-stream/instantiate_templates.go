package main

import (
	"bytes"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"text/template"
)

type User struct {
	Passwd             string
	SSH_authorized_key string
}

func main() {
	// Get publisc SSH key
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
	// Get password hash
	cmd := exec.Command("mkpasswd", "--method=SHA-512", "--rounds=500000")
	var outb, errb bytes.Buffer
	cmd.Stdout = &outb
	cmd.Stderr = &errb
	cmd_err := cmd.Run()
	if cmd_err != nil {
		log.Fatalf("Could not find mkpasswd command! %v", cmd_err)
	}
	user := User{Passwd: outb.String(), SSH_authorized_key: string(ssh_key)}
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
