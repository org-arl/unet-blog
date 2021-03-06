using Plots

theme(:mydark)   # or any other dark theme

f(x) = sin(10-x) * cos((10-x)/10) * exp(-(10-x)/10)
f1(x) = 0.5*sin(2x) + 0.3*sin(1.4x+5) - 0.27
f2(x) = 1.27*sinc(1.3x-3.5) - 0.42

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
  scatter!(p, [2.7], [0.5]; markersize=10, markercolor=RGB(0.220,0.596,0.149), markeralpha=0.5, markerstrokecolor=:black, legend=false)
  scatter!(p, [2.8], [0.4]; markersize=10, markercolor=RGB(0.584,0.345,0.698), markeralpha=0.5, markerstrokecolor=:black, legend=false)
  scatter!(p, [2.6], [0.4]; markersize=10, markercolor=RGB(0.796,0.235,0.200), markeralpha=0.5, markerstrokecolor=:black, legend=false)
  p
end
