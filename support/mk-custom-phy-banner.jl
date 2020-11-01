using Plots

theme(:mydark)   # or any other dark theme

f(x) = sin(x) * cos(x/10) * exp(-x/10)
f1(x) = 0.7*sin(1.3x) + 0.4*sin(1.4x+5) * exp(x/20) - 0.27
f2(x) = 1.27*sinc(1.3x-6.5) - 0.42

let p = plot(f, 0, 10; size=(1300,500), color=RGBA(1,0,0,0.5), legend=false)
  for a ∈ 1.0:-0.001:0.7
    plot!(p, x -> a*f(x), 0, 10; color=RGBA(1,0,0,0.03), legend=false)
  end
  plot!(p, f2, 0, 10; color=RGBA(0,1,0,0.25), legend=false)
  for a ∈ 1.0:-0.001:0.7
    plot!(p, x -> a*f2(x), 0, 10; color=RGBA(0,1,0,0.01), legend=false)
  end
  plot!(p, f1, 0, 10; color=RGBA(0,0,1,0.5), legend=false)
  for a ∈ 1.0:-0.001:0.7
    plot!(p, x -> a*f1(x), 0, 10; color=RGBA(0,0,1,0.03), legend=false)
  end
  p
end
