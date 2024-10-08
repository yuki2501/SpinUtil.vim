" ファイルを掃除する関数
function! CleanPanFilesAndAout()
    let files = ['pan.b', 'pan.c', 'pan.h', 'pan.m', 'pan.p', 'pan.t', 'a.out']
    for file in files
        if filereadable(file)
            call delete(file)
        endif
    endfor
endfunction

" spin -a を実行する関数
function! RunSpinOnCurrentFile()
    let filename = expand('%:p')
    if fnamemodify(filename, ':e') !=# 'pml'
        echohl ErrorMsg
        echo "❌ Error: The current file is not a .pml file."
        echohl None
        return ''
    endif

    let spin_cmd = 'spin -a ' . filename
    let result = system(spin_cmd)
    if v:shell_error
        return result
    endif
    return ''
endfunction

" pan.c をコンパイルする関数
function! CompilePanC()
    let compiler = get(g:, 'spin_c_compiler', 'cc')
    if filereadable('pan.c')
        let compile_cmd = compiler . ' pan.c -o a.out'
        let result = system(compile_cmd)
        if v:shell_error
            return result
        endif
        return ''
    else
        return "❌ pan.c not found"
    endif
endfunction

" 結果表示用の専用バッファを作成
function! OpenResultBuffer()
    " 右側に垂直分割で新しいバッファを作成
    vsplit
    vertical resize 40  " ウィンドウの幅を40に設定
    enew  " 新しいバッファを作成
    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal noswapfile
    setlocal nonumber norelativenumber " 行番号を非表示に
    return bufnr('%')  " 新しいバッファ番号を返す
endfunction

" a.out を実行し、結果を専用バッファに表示
function! RunAoutAndShowResult()
    if filereadable('a.out')
        let result = system('./a.out')
        
        " 結果表示用のバッファを開く
        let bufnum = OpenResultBuffer()

        " 結果を新しいバッファに出力
        if result =~ 'assertion violated'
            call setbufline(bufnum, 1, '❌ Verification failed: ' . result)
        else
            call setbufline(bufnum, 1, '🟢 Verification successful')
        endif
    else
        echohl ErrorMsg
        echo "❌ a.out not found"
        echohl None
    endif
endfunction

" 全体のメイン機能を実行する関数
function! MainSpinProcess()
    " ファイルの掃除
    call CleanPanFilesAndAout()

    " spin -a の実行
    let spin_error = RunSpinOnCurrentFile()
    if !empty(spin_error)
        echohl ErrorMsg
        echo "❌ Spin failed: " . spin_error
        echohl None
        return
    endif

    " pan.c のコンパイル
    let compile_error = CompilePanC()
    if !empty(compile_error)
        echohl ErrorMsg
        echo "❌ Compilation failed: " . compile_error
        echohl None
        return
    endif

    " a.out の実行結果を表示
    call RunAoutAndShowResult()
endfunction

" Vim コマンドとして公開
command! RunSpin call MainSpinProcess()

