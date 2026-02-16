package main

import "core:path/filepath"
import "core:os"
import "core:fmt"
import "core:c/libc"
import "core:strings"



create_exe :: proc(path: string){
    cmd_as_str := fmt.tprintf("as ./.build/%s.s -o ./.build/%s.o", path, path)
    libc.system(strings.unsafe_string_to_cstring(cmd_as_str))

    cmd_ld_str := fmt.tprintf("ld ./.build/%s.o -o %s", path, path)
    libc.system(strings.unsafe_string_to_cstring(cmd_ld_str))
}

code_gen :: proc(tokens: ^[]Token){
    path:= ".build/teste.s"

    dir := filepath.dir(path)
    defer delete(dir)
    if !os.exists(dir) {
        err := os.make_directory(dir)
        if err != os.ERROR_NONE {
            fmt.eprintln("Erro Creating Dir:", err)
            return
        }
    }


    f, _ := os.open(path, os.O_WRONLY | os.O_CREATE | os.O_TRUNC, 0o644)
    defer os.close(f)

    fmt.fprintf(f,".intel_syntax noprefix\n")
    fmt.fprintf(f,".global _start\n")
    fmt.fprintf(f,".text\n")
    fmt.fprintf(f,"jmp _start\n")

    current_is_main := false

    buffer_cout: int = 0

    for _, i in tokens{
        if tokens[i].label{


            if tokens[i + 1].kind == .ASSING{
                if tokens[i + 2].label{
                    fmt.fprintf(f,".text\n")
                    fmt.fprintf(f,"mov r15, [%v]\n",tokens[i + 2].symbol)
                    fmt.fprintf(f,"mov [%v], r15\n",tokens[i].symbol)
                }
            }


            if tokens[i + 1].kind == .LPR{

                if tokens[i + 2].label && tokens[i].symbol == Core[.PRINT]{
                    if tokens[i + 3].kind == .RPR{
                        fmt.fprintf(f,".text\n")
                        fmt.fprintf(f,"lea rdi, [%v]\n",tokens[i + 2].symbol)
                        fmt.fprintf(f,"call _print\n")
                    }
                }

                 if tokens[i + 2].kind == .DATA && tokens[i].symbol == Core[.PRINT]{
                    if tokens[i + 3].kind == .RPR{
                        if tokens[i + 2].type == .STR{
                            buffer_cout += 1
                            fmt.fprintf(f,".data\n")
                            fmt.fprintf(f,"buffer%d: .asciz %v\n",buffer_cout,tokens[i + 2].val)
                            fmt.fprintf(f,".text\n")
                            fmt.fprintf(f,"lea rdi, buffer%d\n",buffer_cout)
                            fmt.fprintf(f,"call _print\n")
                        }
                        if tokens[i + 2].type == .I32{
                            buffer_cout += 1
                            fmt.fprintf(f,".data\n")
                            fmt.fprintf(f,"buffer%d: .asciz \"%v\\n\"\n",buffer_cout,tokens[i + 2].val)
                            fmt.fprintf(f,".text\n")
                            fmt.fprintf(f,"lea rdi, buffer%d\n",buffer_cout)
                            fmt.fprintf(f,"call _print\n")
                        }

                    }
                }


             if tokens[i + 2].kind == .RPR{
                    fmt.fprintf(f,".text\n")
                    fmt.fprintf(f,"call _%v\n",tokens[i].symbol)
                }


            }


            if tokens[i + 1].kind == .COLUM{
                if tokens[i + 2].type == .STR{
                    if tokens[i + 3].kind == .ASSING{
                        if tokens[i + 4].kind == .DATA{
                            fmt.fprintf(f,".data\n")
                            fmt.fprintf(f,"%v: .asciz %v\n",tokens[i].symbol,tokens[i + 4].val)

                        }

                    }
                }

                if tokens[i + 2].type == .I32{
                    if tokens[i + 3].kind == .ASSING{
                        if tokens[i + 4].kind == .DATA{
                            fmt.fprintf(f,".data\n")
                            fmt.fprintf(f,"%v: .double %v\n",tokens[i].symbol,tokens[i + 4].val)

                        }

                    }
                }

            }

             if tokens[i + 1].kind == .DCOLUM && tokens[i].symbol == "main"{
                current_is_main = true
                fmt.fprintf(f,".text\n")
                fmt.fprintf(f,"_start:\n")
            }

            if tokens[i + 1].kind == .DCOLUM && tokens[i].symbol != "main"{
                current_is_main = false
                fmt.fprintf(f,".text\n")
                fmt.fprintf(f,"_%v:\n",tokens[i].symbol)
            }


        }


        if tokens[i].kind == .RB{
            if current_is_main {
                fmt.fprintf(f, "jmp _exit\n")
            }else {
                fmt.fprintf(f, "ret\n")
            }
        }

    }


    fmt.fprint(f,

`

_exit:
mov eax,60
xor rdi, rdi
syscall

_print:
push rdi
call _strlen
pop  rdi

mov rdx, rax
mov rsi, rdi
mov rax, 1
mov rdi, 1
syscall
ret


_strlen:
mov rax, rdi
xor rcx, rcx

loop:
mov bl, [rax]
cmp bl, 0
je _strlen_exit
inc rcx
inc rax
jmp loop
_strlen_exit:
mov rax, rcx
ret
`
    )




}
