package main

import "core:os"
import "core:fmt"
import "core:path/filepath"
import "core:unicode"


readFile :: proc(path: string) -> []byte{
    f, err:= os.open(path)
    if err != nil {
        fmt.printf("open error: %v\n", err)
        os.exit(1)
    }
    defer os.close(f)
    size,_:= os.file_size(f)
    buffer := make([]byte,size)

    os.read(f,buffer)
    return buffer
}


main :: proc(){

    // arg:= os.args[1]
    arg:= "teste.txt"
    file_name:= filepath.stem(arg)

    data:= readFile(arg)
    defer delete(data)

    tokens:= parse(&data)
    defer free_all(context.temp_allocator)

    assign_types(&tokens)
    type_check(&tokens)

    code_gen(&tokens)

    create_exe(file_name)

    // fmt.println(unicode.is_punct('+'))
    // fmt.println(rune(32))


    // for tks in tokens {
    //     fmt.println(tks)
    //     // if tks.label{
    //     //     fmt.println(tks)
    //     // }
    // }
}
