" ファイルを掃除する関数
function! CleanPanFilesAndAout()
    " 削除対象のファイルリスト
    let files = ['pan.b', 'pan.c', 'pan.h', 'pan.m', 'pan.p', 'pan.t', 'a.out']

    " 各ファイルを削除
    for file in files
        if filereadable(file)
            call delete(file)
            echo "Deleted: " . file
        endif
    endfor

    " 削除完了のメッセージ
    echo "Cleaned pan.* files and a.out."
endfunction

" spin -a を実行する関数
function! RunSpinOnCurrentFile()
    " 現在開いているファイル名を取得
    let filename = expand('%:p')

    " 拡張子が .pml かどうか確認
    if fnamemodify(filename, ':e') !=# 'pml'
        echohl ErrorMsg
        echo "❌ Error: The current file is not a .pml file."
        echohl None
        return ''
    endif

    " spin -a を実行
    let spin_cmd = 'spin -a ' . filename
    let result = system(spin_cmd)

    if v:shell_error
        return result  " 失敗した場合はエラーメッセージを返す
    endif

    return ''  " 成功した場合は空文字列を返す
endfunction

" pan.c をコンパイルする関数
function! CompilePanC()
    let compiler = get(g:, 'spin_c_compiler', 'cc')

    if filereadable('pan.c')
        let compile_cmd = compiler . ' pan.c -o a.out'
        let result = system(compile_cmd)

        if v:shell_error
            return result  " コンパイル失敗時
        endif

        return ''  " コンパイル成功時
    else
        return "❌ pan.c not found"
    endif
endfunction

" a.out を実行し、結果を右側バッファに表示する関数
function! RunAoutAndShowResult()
    if filereadable('a.out')
        let result = system('./a.out')

        " 右側に新しいバッファを開く
        vsplit
        vertical resize 40  " ウィンドウサイズ調整
        setlocal buftype=nofile
        setlocal bufhidden=wipe
        setlocal noswapfile

        " 実行結果を表示
        if result =~ 'assertion violated'
            call setline(1, '❌ Verification failed: ' . result)
        else
            call setline(1, '🟢 Verification successful')
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

