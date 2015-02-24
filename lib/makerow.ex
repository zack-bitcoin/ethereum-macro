defmodule Makerow do
	def grab_till(t, s) do
		cond do
			t==[] -> 1=2
			hd(t) == s -> []
			true -> [hd(t)|grab_till(tl(t), s)]
		end
	end
	def skip_till(t, a) do
		cond do
			t==[] -> 1=2
			hd(t)==a -> tl(t)
			true -> skip_till(tl(t), a)
		end
	end
	def grab_macro(t) do
		cond do
			t==[] -> 1=2
			hd(t)==:"#" -> grab_till(tl(t), :";")
			true -> grab_macro(tl(t))
		end
	end
	def remove_macro(t) do
		cond do
			t==[] -> []
			hd(t)==:"#" -> skip_till(tl(t), :";")
			true -> [hd(t)|remove_macro(tl(t))]
		end
	end
	def remove_macros(t) do
		b=t
		t=remove_macro(t)
		cond do
			b==t -> t
			true -> remove_macros(t)
		end
	end
	def macros(t) do
		cond do
			:"#" in t -> [grab_macro(t)|macros(remove_macro(t))]
			true -> []
		end
	end
	def first(times, data) do
		IO.puts "first #{inspect data}"
		cond do
			times<=0 -> []
			data == [] -> []
			true -> [hd(data)|first(times-1, tl(data))]
		end
	end
	def times(tmes, data, func) do
		cond do
			tmes<=0 -> data
			true -> times(tmes-1, func.(data), func)
		end
	end
	def order(macro) do
		Enum.reduce(tl(macro), 0, fn(w, acc) ->
			<<a::size(8), b::binary>>=to_string(w)
			#IO.puts "w #{to_string(w)}"
			#IO.puts "a b acc macro #{inspect a} #{inspect macro} #{inspect macro} #{inspect macro}"
			cond do
				<<a>>=="&" -> max(String.to_integer(b), acc)
				true -> acc
			end
		end)
	end
	def ampersan(x) do
		<<a::size(8), b::binary>> = to_string(x)
		"&"==<<a>>
	end
	def fillin(keys, macro) do
		cond do
			macro==[] -> []
			ampersan(hd(macro)) -> 
				<<a::size(8), b::binary>> = to_string(hd(macro))
				i=String.to_integer(b)-1
				#IO.puts "a b macro i #{inspect a} #{inspect b} #{inspect macro} #{inspect i}"
				IO.puts "keys #{inspect keys}"
				IO.puts "macro #{inspect macro}"
				[elem(keys, i)|fillin(keys, tl(macro))] 
			true -> [hd(macro)|fillin(keys, tl(macro))]
		end
	end
	def test_fillin do
		IO.puts inspect fillin({4, 5}, [:abc, :"&1", :a, :"&2"])
	end
	def apply_macro(m, code) do
		cond do
			code==[] -> []
			hd(code)==hd(m) -> 
				size = order(m)+1
				keys = List.to_tuple(first(size, tl(code)))#code is a macro??
				IO.puts "rest of code #{inspect code}"
				IO.puts "size #{inspect size}"
				code = times(size, code, &(tl(&1)))
				IO.puts "rest of code #{inspect code}"
				fillin(keys, tl(m)) ++ apply_macro(m, code)
			true -> [hd(code)|apply_macro(m, tl(code))]
		end
	end
	def test_apply_macro do
		#m=[ :square, :dup1, :mul ]
		#m=[ :square, :"&1", :dup1, :mul ]
		m=[ :squaresum, :"&1", :dup1, :mul, :"&2", :dup1, :mul, :add ]
		code = [ :squaresum, :"5", :"3" ]
		apply_macro(m, code)
	end
	def apply_macros(macros, code) do
		cond do
			macros == [] -> code
			true -> apply_macros(tl(macros), apply_macro(hd(macros), code))
		end
	end
	def macros_doer(t) do
		mcs = macros(t)
		t = remove_macros(t)
		IO.puts "t mcs #{inspect t} #{inspect mcs}"
		mcs = Enum.map(mcs, &([hd(&1)|apply_macros(mcs,tl(&1))]))
		#mcs = Enum.map(mcs, &(apply_macros(mcs,&1)))
		#mcs = Enum.map(mcs, &(apply_macros(mcs,&1)))
		IO.puts "MMMMmcs ##{inspect mcs}"
		apply_macros(mcs, t)
	end
	def compile(t) do
		t |> Assembler.read |> macros_doer |> Assembler.compile2
	end
	def main(args) do
		args=hd(args)
		cond do 
			args==[] -> IO.puts "not enough args. example: ./assembler file.asm"
			args=="-h" -> IO.puts "usage: ./assembler code.asm"
			args=="--help" -> IO.puts "usage: ./assembler code.asm"
			true ->
				{:ok, text} = File.read args
				IO.puts inspect compile(text)
		end
	end
end
