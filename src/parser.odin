package main

import "core:unicode"
import "core:unicode/utf8"
import "core:strconv"
import "core:fmt"


Parser :: struct{
    tokens: [dynamic]Token,
    charbuf: [dynamic]rune,
    peak: rune,
    peak_count:int,
    skip:  bool,
    skip_count: int,
    line: int,
    ch_count:   int
}

has_operations :: proc(tokens: ^[dynamic]Token) -> bool{

    has_operations: bool = false

    for tks in tokens{
        if tks.kind == .ADD{
            has_operations = true
            return has_operations
        }
        if tks.kind == .MULT{
            has_operations = true
            return has_operations
        }
        if tks.kind == .SUB{
            has_operations = true
            return has_operations
        }
        if tks.kind == .DIV{
            has_operations = true
            return has_operations
        }
    }

    has_operations = false
    return has_operations
}

check_operations :: proc(tokens: ^[dynamic]Token){
    for &tks, i in tokens{
        if tks.kind == .DATA{
           if tokens[i + 1].kind == .ADD{
               if tokens[i + 2].kind == .DATA{
                    switch v in tks.val{
                        case string:
                            fmt.println("Its string")
                        case i32:
                            a:= tks.val.(i32)
                            b:= tokens[i + 2].val.(i32)
                            tks.val = a + b
                            ordered_remove(tokens,i + 2)
                            ordered_remove(tokens,i + 1)
                    }
                }
            }

        if tokens[i + 1].kind == .MULT{
               if tokens[i + 2].kind == .DATA{
                    switch v in tks.val{
                        case string:
                            fmt.println("Its string")
                        case i32:
                            a:= tks.val.(i32)
                            b:= tokens[i + 2].val.(i32)
                            tks.val = a * b
                            ordered_remove(tokens,i + 2)
                            ordered_remove(tokens,i + 1)
                    }
                }
            }


        if tokens[i + 1].kind == .SUB{
               if tokens[i + 2].kind == .DATA{
                    switch v in tks.val{
                        case string:
                            fmt.println("Its string")
                        case i32:
                            a:= tks.val.(i32)
                            b:= tokens[i + 2].val.(i32)
                            tks.val = a - b
                            ordered_remove(tokens,i + 2)
                            ordered_remove(tokens,i + 1)
                    }
                }
            }



     if tokens[i + 1].kind == .DIV{
               if tokens[i + 2].kind == .DATA{
                    switch v in tks.val{
                        case string:
                            fmt.println("Its string")
                        case i32:
                            a:= tks.val.(i32)
                            b:= tokens[i + 2].val.(i32)
                            tks.val = a / b
                            ordered_remove(tokens,i + 2)
                            ordered_remove(tokens,i + 1)
                    }
                }
            }



        }
    }
}


parse :: proc(data: ^[]byte) -> []Token{


    clearToken :: proc(t: ^Token){
        t^.kind  = .EMPTY
        t^.type  = .EMPTY
        t^.line  = 0
        t^.pos   = 0
        t^.label =  false
        t^.symbol = ""
        t^.val = nil
    }

    tokenizer: Tokenizer
    token: Token
    parser: Parser

    parser.charbuf = make([dynamic]rune,context.temp_allocator)
    parser.tokens  = make([dynamic]Token,context.temp_allocator)

    parser.line = 1

    for _,i in data{

         if i + parser.peak_count < len(data){
            parser.peak_count = 1
            parser.peak = rune(data[i + parser.peak_count])
         }

         parser.ch_count += 1
         if data[i] == '\n'{
            parser.line += 1
            parser.ch_count = 0
        }

        if parser.skip_count <= 0 {
            parser.skip = false
        }
        if parser.skip {
            parser.skip_count -=1
            continue
        }



       if  unicode.is_alpha(rune(data[i])){
            append(&parser.charbuf,rune(data[i]))

            if rune(data[i + 1]) == '\n'{
                token.kind  = .EMPTY
                token.label =  true
                token.type  = .EMPTY
                token.line  = parser.line
                token.pos   = parser.ch_count
                token.symbol = utf8.runes_to_string(parser.charbuf[:],context.temp_allocator)
                append(&parser.tokens,token)
                clearToken(&token)
                clear(&parser.charbuf)
            }


            for unicode.is_space(parser.peak){
                parser.peak_count += 1
                parser.peak = rune(data[i + parser.peak_count])
            }


            switch parser.peak{

                case ':':
                    token.kind  = .EMPTY
                    token.label =  true
                    token.type  = .EMPTY
                    token.line  = parser.line
                    token.pos   = parser.ch_count
                    token.symbol = utf8.runes_to_string(parser.charbuf[:],context.temp_allocator)
                    append(&parser.tokens,token)
                    clearToken(&token)
                    clear(&parser.charbuf)

                case '=':
                    token.kind  = .EMPTY
                    token.label =  true
                    token.type  = .EMPTY
                    token.line  = parser.line
                    token.pos   = parser.ch_count
                    token.symbol = utf8.runes_to_string(parser.charbuf[:],context.temp_allocator)
                    append(&parser.tokens,token)
                    clearToken(&token)
                    clear(&parser.charbuf)

                 case '(':
                    token.kind  = .EMPTY
                    token.label =  true
                    token.type  = .EMPTY
                    token.line  = parser.line
                    token.pos   = parser.ch_count
                    token.symbol = utf8.runes_to_string(parser.charbuf[:],context.temp_allocator)
                    append(&parser.tokens,token)
                    clearToken(&token)
                    clear(&parser.charbuf)

                case ')':
                    token.kind  = .EMPTY
                    token.label =  true
                    token.type  = .EMPTY
                    token.line  = parser.line
                    token.pos   = parser.ch_count
                    token.symbol = utf8.runes_to_string(parser.charbuf[:],context.temp_allocator)
                    append(&parser.tokens,token)
                    clearToken(&token)
                    clear(&parser.charbuf)

                case '\r':
                    token.kind  = .EMPTY
                    token.label =  true
                    token.type  = .EMPTY
                    token.line  = parser.line
                    token.pos   = parser.ch_count
                    token.symbol = utf8.runes_to_string(parser.charbuf[:],context.temp_allocator)
                    append(&parser.tokens,token)
                    clearToken(&token)
                    clear(&parser.charbuf)
            }


            switch rune(data[i]){
                case 's':
                    if parser.peak == 't'{
                        parser.peak_count += 1
                        parser.peak = rune(data[i + parser.peak_count])
                        if parser.peak == 'r'{
                            token.kind  = .EMPTY
                            token.label =  false
                            token.type  = .STR
                            token.line  = parser.line
                            token.pos   = parser.ch_count
                            token.symbol = "str"
                            append(&parser.tokens,token)
                            clearToken(&token)
                            clear(&parser.charbuf)
                            parser.skip_count = 2
                            parser.skip = true
                        }
                    }


                case 'i':
                        if parser.peak == '3'{
                            parser.peak_count += 1
                            parser.peak = rune(data[i + parser.peak_count])
                            if parser.peak == '2'{
                                token.kind  = .EMPTY
                                token.label =  false
                                token.type  = .I32
                                token.line  = parser.line
                                token.pos   = parser.ch_count
                                token.symbol = "i32"
                                append(&parser.tokens,token)
                                clearToken(&token)
                                clear(&parser.charbuf)
                                parser.skip_count = 2
                                parser.skip = true
                            }
                        }


            }


        }


        if unicode.is_digit(rune(data[i])){
                    append(&parser.charbuf,rune(data[i]))
                    for unicode.is_digit(parser.peak){
                        append(&parser.charbuf,parser.peak)
                        parser.skip_count += 1
                        parser.peak_count += 1
                        parser.peak = rune(data[i + parser.peak_count])
                    }
                    token.kind  = .DATA
                    token.label =  false
                    token.type  = .I32
                    token.line  = parser.line
                    token.pos   = parser.ch_count
                    s:= utf8.runes_to_string(parser.charbuf[:],context.temp_allocator)
                    val,_:= strconv.parse_int(s)
                    token.val = i32(val)
                    append(&parser.tokens,token)
                    clearToken(&token)
                    clear(&parser.charbuf)
                    // parser.skip_count += 0
                    parser.skip = true

        }

        if unicode.is_symbol(rune(data[i])){
            switch rune(data[i]){
                case'+':
                    token.kind  = .ADD
                    token.label =  false
                    token.type  = .EMPTY
                    token.line  = parser.line
                    token.pos   = parser.ch_count
                    token.symbol = "+"
                    append(&parser.tokens,token)
                    clearToken(&token)
                    clear(&parser.charbuf)
            }
        }


        if unicode.is_punct(rune(data[i])){
            switch rune(data[i]){


                case'-':
                        token.kind  = .SUB
                        token.label =  false
                        token.type  = .EMPTY
                        token.line  = parser.line
                        token.pos   = parser.ch_count
                        token.symbol = "-"
                        append(&parser.tokens,token)
                        clearToken(&token)
                        clear(&parser.charbuf)

                case'*':
                        token.kind  = .MULT
                        token.label =  false
                        token.type  = .EMPTY
                        token.line  = parser.line
                        token.pos   = parser.ch_count
                        token.symbol = "*"
                        append(&parser.tokens,token)
                        clearToken(&token)
                        clear(&parser.charbuf)

                case'/':
                    token.kind  = .DIV
                    token.label =  false
                    token.type  = .EMPTY
                    token.line  = parser.line
                    token.pos   = parser.ch_count
                    token.symbol = "/"
                    append(&parser.tokens,token)
                    clearToken(&token)
                    clear(&parser.charbuf)


                case'(':
                    token.kind  = .LPR
                    token.label =  false
                    token.type  = .EMPTY
                    token.line  = parser.line
                    token.pos   = parser.ch_count
                    token.symbol = "("
                    append(&parser.tokens,token)
                    clearToken(&token)
                    clear(&parser.charbuf)

                case')':
                    token.kind  = .RPR
                    token.label =  false
                    token.type  = .EMPTY
                    token.line  = parser.line
                    token.pos   = parser.ch_count
                    token.symbol = ")"
                    append(&parser.tokens,token)
                    clearToken(&token)
                    clear(&parser.charbuf)

                case'{':
                    token.kind  = .LB
                    token.label =  false
                    token.type  = .EMPTY
                    token.line  = parser.line
                    token.pos   = parser.ch_count
                    token.symbol = "{"
                    append(&parser.tokens,token)
                    clearToken(&token)
                    clear(&parser.charbuf)

                case'}':
                    token.kind  = .RB
                    token.label =  false
                    token.type  = .EMPTY
                    token.line  = parser.line
                    token.pos   = parser.ch_count
                    token.symbol = "}"
                    append(&parser.tokens,token)
                    clearToken(&token)
                    clear(&parser.charbuf)


                case ':':


                    if parser.peak == ':'{
                        token.kind  = .DCOLUM
                        token.label =  false
                        token.type  = .EMPTY
                        token.line  = parser.line
                        token.pos   = parser.ch_count
                        token.symbol = "::"
                        append(&parser.tokens,token)
                        clearToken(&token)
                        clear(&parser.charbuf)
                        parser.skip_count = 1
                        parser.skip = true
                    }else{
                        token.kind  = .COLUM
                        token.label =  false
                        token.type  = .EMPTY
                        token.line  = parser.line
                        token.pos   = parser.ch_count
                        token.symbol = ":"
                        append(&parser.tokens,token)
                        clearToken(&token)
                        clear(&parser.charbuf)
                    }

                case '"':

                    append(&parser.charbuf,'"')
                    for parser.peak != '"'{
                        append(&parser.charbuf,parser.peak)
                        parser.skip_count += 1
                        parser.peak_count += 1
                        parser.peak = rune(data[i + parser.peak_count])
                    }
                    append(&parser.charbuf,'"')
                    token.kind  = .DATA
                    token.label =  false
                    token.type  = .STR
                    token.line  = parser.line
                    token.pos   = parser.ch_count
                    token.val = utf8.runes_to_string(parser.charbuf[:],context.temp_allocator)
                    append(&parser.tokens,token)
                    clearToken(&token)
                    clear(&parser.charbuf)
                    parser.skip_count += 1
                    parser.skip = true

            }
        }



    if unicode.is_symbol(rune(data[i])){

        switch rune(data[i]){
            case '=':
                token.kind  = .ASSING
                token.label =  false
                token.type  = .EMPTY
                token.line  = parser.line
                token.pos   = parser.ch_count
                token.symbol = "="
                append(&parser.tokens,token)
                clearToken(&token)
                clear(&parser.charbuf)
        }
    }




    }

    for has_operations(&parser.tokens){
        check_operations(&parser.tokens)
    }

    return parser.tokens[:]

}
