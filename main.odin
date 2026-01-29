package main

import "core:os"
import "core:fmt"
import "core:unicode"
import "core:strings"
import "core:strconv"
import "base:runtime"
import "core:c/libc"
import "core:path/filepath"

buffer: []u8

Lexer :: struct{
    tokens: [dynamic]Token,
    peak:u8,
}

Symbol :: enum{
    LABEL,
    COLUM,
    DCOLUM,
    VAL,
    I32,
    STR,
    LPR,
    RPR,
    LB,
    RB,
    NULL
}

Type :: enum{
    I32,
    STR,
    NULL
}


Core :: enum{
    PRINT
}


Builtin :: [Core]string{
    .PRINT = "print"
}


Token :: struct{
    simbol: Symbol,
    type:   Type,
    token: string,
    val: i32,
    str: string
}

Tokens :: []Token



assign_types :: proc(tks: ^Tokens){


    for &t, i in tks {

        if t.simbol == .LABEL{
            if tks[i + 1].simbol == .COLUM{
                if tks[i + 2].type == .STR{
                    t.type = .STR
                    t.str = tks[i + 3].str
                }
            }

            if tks[i + 1].simbol == .COLUM{
                if tks[i + 2].type == .I32{
                    t.type = .I32
                    t.val = tks[i + 3].val
                }
            }

        }
    }

    for t, i in tks {
        for &tt in tks{
            if tt.token != "="{
               if tt.token == t.token{
                tt.type = t.type
                tt.str = t.str
                tt.val = t.val
                }
            }

        }
    }
}

check_type :: proc(tks: ^Tokens){


    for &t, i in tks {

        if t.simbol == .LABEL{

            if tks[i + 1].simbol == .VAL{
                if tks[i + 2].simbol == .VAL{
                    if tks[i + 2].type != tks[i].type{
                        fmt.eprintln("Different Types",tks[i + 2].type, tks[i].type)
                        os.exit(1)
                    }
                }

            }

        }
    }


}


parse :: proc() -> Tokens{

    lexer: Lexer

    token: Token

    charbuf:[dynamic]u8 = make([dynamic]u8,context.temp_allocator)
    lexer.tokens = make([dynamic]Token,context.allocator)
    defer free_all(context.temp_allocator)



    clearToken :: proc(t: ^Token){
        t^.simbol = .NULL
        t^.type =  .NULL
        t^.token = ""
        t^.val = 0
        t^.str = ""
    }

    skip:bool = false
    skip_count:= 0

    for _,i in buffer{
        // fmt.println("SKIP: ",skip_count)
        if skip_count <= 0 {skip = false}
        if skip{skip_count -=1;continue}
        if unicode.is_alpha(rune(buffer[i])){
            count:= 0
            append(&charbuf,buffer[i])
            lexer.peak = buffer[i + 1]
            for unicode.is_space(rune(lexer.peak)){
                count +=1
                lexer.peak = buffer[i + count]
            }

            if rune(lexer.peak) == '('{
                s:= strings.clone_from_bytes(charbuf[:])
                clearToken(&token)
                token.token = s
                token.simbol = .LABEL
                append(&lexer.tokens,token)
                clear(&charbuf)
            }

             if rune(lexer.peak) == '='{
                lexer.peak = buffer[i + 1]
                for unicode.is_space(rune(lexer.peak)){
                    count +=1
                    lexer.peak = buffer[i + count]
                }

                if unicode.is_alpha(rune(lexer.peak)){
                    s:= strings.clone_from_bytes(charbuf[:])
                    clearToken(&token)
                    token.token = s
                    token.simbol = .LABEL
                    append(&lexer.tokens,token)
                    clear(&charbuf)
                }

            }



            if rune(lexer.peak) == ':'{
                s:= strings.clone_from_bytes(charbuf[:])
                clearToken(&token)
                token.token = s
                token.simbol = .LABEL
                append(&lexer.tokens,token)
                clear(&charbuf)
            }
            if rune(buffer[i]) == 'i'{
                lexer.peak = buffer[i + 1]
                if rune(lexer.peak) == '3'{
                    lexer.peak = buffer[i + 2]
                    if rune(lexer.peak) == '2'{
                        clearToken(&token)
                        append(&charbuf,buffer[i + 2])
                        append(&charbuf,buffer[i + 1])
                        append(&charbuf,buffer[i])
                        s:= strings.clone_from_bytes(charbuf[:])
                        token.token = ".double"
                        token.type = .I32
                        token.simbol = .I32
                        append(&lexer.tokens,token)
                        clear(&charbuf)
                    }
                }
            }

            if rune(buffer[i]) == 's'{
                lexer.peak = buffer[i + 1]
                if rune(lexer.peak) == 't'{
                    lexer.peak = buffer[i + 2]
                    if rune(lexer.peak) == 'r'{
                        clearToken(&token)
                        append(&charbuf,buffer[i + 2])
                        append(&charbuf,buffer[i + 1])
                        append(&charbuf,buffer[i])
                        s:= strings.clone_from_bytes(charbuf[:])
                        token.token = ".asciz"
                        token.type = .STR
                        token.simbol = .STR
                        append(&lexer.tokens,token)
                        clear(&charbuf)
                    }
                }

            }

        }


        if unicode.is_punct(rune(buffer[i])){
            if rune(buffer[i]) == ':'{
                lexer.peak = buffer[i - 1]
                if rune(lexer.peak) != ':'{
                    lexer.peak = buffer[i + 1]
                    if rune(lexer.peak) == ':'{
                        clearToken(&token)
                        append(&charbuf,buffer[i + 1])
                        append(&charbuf,buffer[i])
                        s:= strings.clone_from_bytes(charbuf[:])
                        token.token = s
                        token.simbol = .DCOLUM
                        append(&lexer.tokens,token)
                        clear(&charbuf)
                    }else{
                        clearToken(&token)
                        append(&charbuf,buffer[i])
                        s:= strings.clone_from_bytes(charbuf[:])
                        token.token = s
                        token.simbol = .COLUM
                        append(&lexer.tokens,token)
                        clear(&charbuf)
                    }
                }

            }

            if rune(buffer[i]) == '('{
                clearToken(&token)
                append(&charbuf,buffer[i])
                token.simbol = .LPR
                token.token = "("
                append(&lexer.tokens,token)
                clear(&charbuf)

                if unicode.is_alpha(rune(buffer[i + 1])){
                    count:= 1
                    lexer.peak = buffer[i + count]
                    for rune(lexer.peak) != ')'{
                        append(&charbuf,lexer.peak)
                        count +=1
                        lexer.peak = buffer[i + count]
                    }
                    clearToken(&token)
                    s:= strings.clone_from_bytes(charbuf[:])
                    token.token = s
                    token.simbol = .LABEL
                    append(&lexer.tokens,token)
                    clear(&charbuf)
                }

            }
            if rune(buffer[i]) == ')'{
                clearToken(&token)
                append(&charbuf,buffer[i])
                token.simbol = .RPR
                token.token = ")"
                append(&lexer.tokens,token)
                clear(&charbuf)
            }
            if rune(buffer[i]) == '{'{
                clearToken(&token)
                append(&charbuf,buffer[i])
                token.simbol = .LB
                token.token = "{"
                append(&lexer.tokens,token)
                clear(&charbuf)
            }
            if rune(buffer[i]) == '}'{
                clearToken(&token)
                append(&charbuf,buffer[i])
                token.simbol = .RB
                token.token = "}"
                append(&lexer.tokens,token)
                clear(&charbuf)
            }


        }
        if unicode.is_symbol(rune(buffer[i])) && rune(buffer[i]) == '='{
            count:= 0
            append(&charbuf,buffer[i])
            s:= strings.clone_from_bytes(charbuf[:])
            token.token = s
            token.simbol = .VAL
            clear(&charbuf)
            lexer.peak = buffer[i + 1]
            for unicode.is_space(rune(lexer.peak)){
                count +=1
                lexer.peak = buffer[i + count]
            }

            if unicode.is_digit(rune(lexer.peak)){
                for unicode.is_digit(rune(lexer.peak)){
                    append(&charbuf,lexer.peak)
                    count +=1
                    lexer.peak = buffer[i + count]
                }
                s = strings.clone_from_bytes(charbuf[:])
                val,_:= strconv.parse_int(s)
                token.val = i32(val)
                clear(&charbuf)
                append(&lexer.tokens,token)
                clearToken(&token)
            }

             if unicode.is_alpha(rune(lexer.peak)){
                token.token = "="
                token.val = 0
                clear(&charbuf)
                append(&lexer.tokens,token)
                clearToken(&token)


                 for unicode.is_alpha(rune(lexer.peak)){
                    append(&charbuf,lexer.peak)
                    count +=1
                    lexer.peak = buffer[i + count]
                    skip_count +=1
                }
                s = strings.clone_from_bytes(charbuf[:])
                token.token = s
                token.simbol = .VAL
                token.val = 0
                skip_count +=1
                skip = true
                clear(&charbuf)
                append(&lexer.tokens,token)
                clearToken(&token)
            }


            if unicode.is_punct(rune(lexer.peak)) && rune(lexer.peak) == '"' && skip == false{
                count +=1
                lexer.peak = buffer[i + count]
                append(&charbuf,'"')
                for rune(lexer.peak) != '"'{
                    append(&charbuf,lexer.peak)
                    count +=1
                    lexer.peak = buffer[i + count]
                    skip_count +=1
                }
                append(&charbuf,'"')
                s = strings.clone_from_bytes(charbuf[:])
                token.token = "="
                token.str = s
                skip_count +=2
                skip = true
                clear(&charbuf)
                append(&lexer.tokens,token)
                clearToken(&token)
            }

        }
    }

    return lexer.tokens[:]
}



syntax :: proc(token: ^Tokens){

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


    for _,i in token{


        if token[i].simbol == .LABEL {
            if i + 1 < len(token){
                next_simbol := token[i + 1].simbol

                if token[i].token == Builtin[.PRINT]{
                    if next_simbol == .LPR{
                        next_simbol = token[i + 2].simbol
                        if next_simbol == .LABEL{
                            next_simbol = token[i + 3].simbol
                            if next_simbol == .RPR{

                                fmt.fprintf(f,".text\n")
                                fmt.fprintf(f,"lea rdi, [%v]\n",token[i + 2].token)
                                fmt.fprintf(f,"call _print\n")
                            }
                        }
                    }
                }



                if next_simbol == .VAL{
                    next_simbol = token[i + 2].simbol
                    if next_simbol == .VAL{
                        fmt.fprintf(f,".text\n")
                        fmt.fprintf(f,"mov r15, [%v]\n",token[i + 2].token)
                        fmt.fprintf(f,"mov [%v], r15\n",token[i].token)
                    }
                }


                if next_simbol == .COLUM{
                    next_simbol = token[i + 2].simbol
                    if next_simbol == .I32{
                        next_simbol = token[i + 3].simbol
                        if next_simbol == .VAL{
                            fmt.fprintf(f,".data\n")
                            fmt.fprintf(f,"%v: %v %v\n",token[i].token,token[i + 2].token,token[i + 3].val)
                        }
                    }
                    if next_simbol == .STR{
                        next_simbol = token[i + 3].simbol
                        if next_simbol == .VAL{
                            fmt.fprintf(f,".data\n")
                            fmt.fprintf(f,"%v: %v %v\n",token[i].token,token[i + 2].token,token[i + 3].str)
                        }
                    }

                }
                if next_simbol == .DCOLUM && token[i].token == "main"{
                    current_is_main = true
                    fmt.fprintf(f,".text\n")
                    fmt.fprintf(f,"_start:\n")
                }

                if next_simbol == .DCOLUM && token[i].token != "main"{
                    current_is_main = false
                    fmt.fprintf(f,".text\n")
                    fmt.fprintf(f,"_%v:\n",token[i].token)
                }


                if next_simbol == .LPR{
                    next_simbol = token[i + 2].simbol
                    if next_simbol == .RPR{
                        fmt.fprintf(f,".text\n")
                        fmt.fprintf(f,"call _%v\n",token[i].token)
                    }
                }


            }

        }

        if token[i].simbol == .RB {
            if current_is_main {
                fmt.fprintf(f, "jmp _exit\n")
            } else {
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


scope :: proc(token: ^Tokens,index: int, t_len: int) -> int{
    count:= 0
    end_of_scope:= 0
    for i in index..<t_len {
        if token[i].simbol == .LB{
            count +=1
        }
        if token[i].simbol == .RB{
            count -=1
        }
        if count <= 0 {
            end_of_scope = i
        }
    }
    return end_of_scope
}

readFile :: proc(path: string){
    f, err:= os.open(path)
    if err != nil {
        fmt.printf("open error: %v\n", err)
        return
    }
    defer os.close(f)
    size,_:= os.file_size(f)
    buffer = make([]u8,size,context.temp_allocator)

    r,error:= os.read(f,buffer)

    // fmt.print(string(buffer[0:r]))
}

writeFile :: proc(){

}

main :: proc(){

    arg:= os.args[1]

    // arg:= "teste.txt"

    file_name:= filepath.stem(arg)

    tokens: Tokens

    readFile(arg)
    tokens =  parse()
    assign_types(&tokens)
    check_type(&tokens)

    // for t in tokens{
    //     fmt.println(t)
    // }

    syntax(&tokens)

    cmd_as_str := fmt.tprintf("as ./.build/%s.s -o ./.build/%s.o", file_name, file_name)
    libc.system(strings.unsafe_string_to_cstring(cmd_as_str))

    cmd_ld_str := fmt.tprintf("ld ./.build/%s.o -o %s", file_name, file_name)
    libc.system(strings.unsafe_string_to_cstring(cmd_ld_str))


    // for t in tokens{
    //     if t.simbol == .LABEL {
    //         fmt.println(t)
    //     }
    // }


}
