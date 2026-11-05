// ipctest — prueba de extremo a extremo del bridge Discord IPC en Wine.
//
// Abre el named pipe \\.\pipe\discord-ipc-0 (lo publica winediscordipcbridge),
// envía el handshake de Discord y muestra la respuesta.
//
// Compilar (desde un Linux con Go):
//   GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -o ipctest.exe .
//
// Ejecutar en el MISMO prefijo que el bridge:
//   S=$HOME/.var/app/com.usebottles.bottles/data/bottles/runners/soda-11.0-10
//   B=$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles/gaming
//   env WINEPREFIX="$B" \
//     LD_LIBRARY_PATH="$S/lib:$S/lib/wine/x86_64-unix:$S/lib/wine/i386-unix" \
//     "$S/bin/wine" ipctest.exe
//
// Resultado esperado: PIPE_CONECTADO_OK + respuesta de Discord.
// Con un client_id falso Discord responde {"code":1003,"message":"protocol error"},
// lo cual ya demuestra que el paquete cruzó Wine -> bridge -> socket -> Discord.
package main

import (
	"encoding/binary"
	"encoding/json"
	"fmt"
	"os"
	"syscall"
)

func main() {
	p, _ := syscall.UTF16PtrFromString(`\\.\pipe\discord-ipc-0`)
	h, err := syscall.CreateFile(p,
		syscall.GENERIC_READ|syscall.GENERIC_WRITE,
		0, nil, syscall.OPEN_EXISTING, 0, 0)
	if err != nil {
		fmt.Println("PIPE_OPEN_FAIL:", err)
		os.Exit(1)
	}
	defer syscall.CloseHandle(h)
	fmt.Println("PIPE_CONECTADO_OK")

	payload, _ := json.Marshal(map[string]any{"v": 1, "client_id": "123456789012345678"})
	var lenb [4]byte
	binary.LittleEndian.PutUint32(lenb[:], uint32(len(payload)))

	var n uint32
	if err := syscall.WriteFile(h, lenb[:], &n, nil); err != nil {
		fmt.Println("WRITE_FAIL:", err)
		os.Exit(1)
	}
	if err := syscall.WriteFile(h, payload, &n, nil); err != nil {
		fmt.Println("WRITE_FAIL:", err)
		os.Exit(1)
	}
	fmt.Println("HANDSHAKE_ENVIADO:", string(payload))

	buf := make([]byte, 4096)
	var r uint32
	if err := syscall.ReadFile(h, buf, &r, nil); err != nil {
		fmt.Println("READ_FAIL:", err)
		os.Exit(1)
	}
	fmt.Printf("RESPUESTA (%d bytes): %x\n", r, buf[:r])
	fmt.Printf("RESPUESTA_TEXTO: %q\n", string(buf[:r]))
}
