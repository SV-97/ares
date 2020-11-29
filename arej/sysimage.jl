#= 

Create sysimage using

    > using PackageCompiler
    > create_sysimage([:Images, :ImageView, :Random, :SparseArrays, :LinearAlgebra, :Statistics], sysimage_path="sys_img.so")

and start julia using
    $ julia -Jsys_img.so main.jl PathToNormImage PathToActualImage =#



using ImageView, Images
using SparseArrays
using Random
using LinearAlgebra
using Statistics
