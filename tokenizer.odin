package main

import "core:fmt"

Token_Kind :: enum{
    COLUM,
    DCOLUM,
    ASSING,
    LPR,
    RPR,
    LB,
    RB,
    DATA,
    NULL,

    EMPTY,
}


Token :: struct{
    label:  bool,
    kind:   Token_Kind,
    type:   Type,
    line:   int,
    pos:    int,
    symbol: string,
    val:    union{string,i32}
}


Procs :: enum{
    PRINT
}


Core :: [Procs]string{
    .PRINT = "print"
}

Tokenizer :: struct{
    peak: Token,
    peak_count:int,
    tokens: []Token
}



type_check :: proc(tokens: ^[]Token){

    for tks, i in tokens{
        if tks.label{
           if tokens[i + 1].kind == .ASSING{
               if tokens[i + 2].label{
                    if tokens[i].type != tokens[i + 2].type{
                        fmt.eprintfln("%v:%v Different Types %v %v %v %v %v",tokens[i].line,tokens[i].pos,tokens[i].symbol,tokens[i+1].symbol,tokens[i+2].symbol,tokens[i].type,tokens[i+2].type)
                    }
                }
            }
        }
    }
}

assign_types :: proc(tokens: ^[]Token){

    //First assignment

    for &tks,i in tokens{
        if tks.label{
            if tokens[i + 1].kind == .COLUM{
                if tokens[i + 2].type == .STR{
                    tks.type = .STR
                    if tokens[i + 3].kind == .ASSING{
                            tks.val = tokens[i + 4].val
                    }
                }
                if tokens[i + 2].type == .I32{
                    tks.type = .I32
                    if tokens[i + 3].kind == .ASSING{
                            tks.val = tokens[i + 4].val
                    }
                }
            }
        }
    }



    //Assign same type to rest of labels that are equal

    for tks in tokens{
        if tks.label{
            for &same in tokens{
                if same.label{
                    if same.symbol == tks.symbol{
                        same.type = tks.type
                        same.val  = tks.val
                    }
                }
            }
        }
    }



}





