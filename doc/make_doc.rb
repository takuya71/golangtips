#!/usr/bin/env ruby
# coding: utf-8

# *.go -> (make_doc.rb) -> *.md -> (pandoc) -> *.html

# Golang Tipsなのにrubyで生成するのかよ！というツッコミはなしで。。

## ---------------------------------------------

documents=[
    ["tips_string","文字列"],
    ["tips_time","日付と時刻"],
    ["tips_num","数値"],
    ["tips_slice","配列"],
]

markdown_folder = "markdown"
html_folder = "html"
template_folder ="template"
go_folder="../pkg"

## トップページ作成-------------------------------

fw=open(markdown_folder+"/"+"index.md","w")

fw.puts <<EOF
% 逆引きRuby
## これはなにか
[逆引きRuby](http://www.namaraii.com/rubytips)の内容をGolang化しつつあるものです。

当方も初学者なので、いろいろといい加減なコードが含まれると思いますが
そのつもりでご参照ください。
Go 1.4.1 で確認しています。Golangは仕様変更が激しいので、都度仕様を確認ください。

なお、ソースコードは[Githubに置いてあります](https://github.com/ashitani/golangtips)ので、
何かあればPull Requestでお知らせください。

## 目次
EOF

for d in documents
    fw.puts "- [#{d[1]}](#{d[0]}.html)"
end

fw.puts
fw.puts <<EOF
## Credits

- [RubyTips](http://www.namaraii.com/rubytips) is founded by [TAKEUCHI Hitoshi](http://www.namaraii.com/).

- HTMLs are generated by [Pandoc](http://pandoc.org/) and decorated by [github.css](https://gist.github.com/andyferra/2554919).
- Golang codes are highlighted by [highlight.js](https://highlightjs.org/),
which is released under the [BSD License](./LICENSE.highlightjs.txt).

- The Go gopher was designed by [Renee French](http://reneefrench.blogspot.com/).
The gopher vector data was made by [Takuya Ueda](http://u.hinoichi.net). 
Licensed under the Creative Commons 3.0 Attributions license.
EOF

fw.close()

## 各ページデータ抽出-----------------------------------

for d in documents
    target=d[0]
    name=d[1]

    go=target+".go"
    html=target+".html"
    md=target+".md"

    ## データ抽出-------------------------------

    # modeの定義
    # 0
    # 1//--
    # 1//ほげほげ
    # 2//--
    # 2 func hogehoge(){
    # 2 ...
    # 2}
    # 1//--

    mode=0
    lastmode=0

    texts=[]
    title=""
    code=""
    func=""

    suf=target.sub(/tips_/,"")

    open(go_folder+"/"+target+"/"+go).each do |l|
        l.chomp!()

        if l=~/\/\/-./ 
            mode+=1
        end

        if mode>=3 && lastmode==2
            mode=1
            texts.push([title,code,func])
            title=""
            code=""
            func=""
        end

        if mode==1 && lastmode==1
            title=l.sub(/^\/\//,"")
        end

        if mode==2 && lastmode==2
            code+=(l+"\n")
            if l=~/func (#{suf}_.*)\(/
                func=$1
            end
        end
        lastmode=mode
    end

    ## 書き出し----------------------------

    fw=open(markdown_folder+"/"+md,"w")


    ## 目次
    fw.puts "% 逆引きGolang ("+name+")"
    fw.puts
    texts.each do |x|
        n=x[0].strip()
        fw.puts "- [#{n}](##{x[2]})"
    end
    fw.puts

    ## 各Tips
    texts.each do |x|
        code=x[1]

        # コメント抽出
        comment=code.scan(/\/\*.*\*\//m)[0]
        if comment!=nil
            comment.sub!(/\/\*/,"")
            comment.sub!(/\*\//,"")
        end

        # コメント削除
        code.sub!(/\/\*.*\*\/( )*\n/m,"")

        # 冒頭にimport "fmt"
        code="package main\n\nimport \"fmt\"\n"+code

        #関数名をmainに置き換える
        code.sub!(/func( )*#{x[2]}\(/,"func main(") 

        # import "fmt"の次に改行がない場合は改行追加
        code.sub!(/import "fmt"\nfunc main/,"import \"fmt\"\n\nfunc main")


        # import文のコメントアウト
        code.gsub!(/\/\/( )*import/,"import")

        # 書き出し
        fw.puts "## <a name=\"#{x[2]}\"> #{x[0].strip()}</a>"
        fw.puts comment
        fw.puts "```golang"
        fw.puts code
        fw.puts "```"
        fw.puts 
    end

    fw.close()

end

##------ html生成

com= "pandoc -s -t html5 -c github.css"
com+=" -H #{template_folder}/header.html"
com+=" -B #{template_folder}/before_body.html"
if File.exist?("#{template_folder}/adsense.html")
    com+=" -B #{template_folder}/adsense.html"
end
com+=" -A #{template_folder}/after_body.html"


Dir.glob(markdown_folder+"/*.md").each do |x|
    infile="#{x}"
    outfile = x.sub(/\.md/,".html")
    outfile = outfile.sub(/#{markdown_folder}/,html_folder)
    system (com+" -o #{outfile} #{infile}")
end
