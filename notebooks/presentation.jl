using PyPlot
using Interact
using Distributions
using Convex
using SCS

function cloud!(x, res, start, n, d)
    dim = size(x, 2)
    for i=1:n
        res[start+i, 1] = x[1] + rand(d)
        res[start+i, 2] = x[2] + rand(d)
    end
end

function circle!(x, r, res, start, n, d)
    dim = size(x, 2)
    for i=1:n
        angle = rand() * 2 * pi
        res[start+i, 1] = x[1] + cos(angle) * r + rand(d)
        res[start+i, 2] = x[2] + sin(angle) * r + rand(d)
    end    
end

function lin_sep_two_clouds()
    x = zeros(100, 2)
    cloud!([0 0], x,  0, 50, Normal(0, 0.2))
    cloud!([1 1], x, 50, 50, Normal(0, 0.2))

    y = repeat([1; -1], inner=50)
    x, y    
end

function two_cocentric()
    x = zeros(150, 2)
    cloud!( [0 0],      x,  0,  50, Normal(0, 0.1))
    circle!([0 0], 1.5, x, 50, 100, Normal(0, 0.1))

    y = repeat([1; -1; -1], inner=50)
    x, y
end

function transform_grid!(f, xgrid, ygrid, zgrid)
    N = size(xgrid,1)

    for i in 1:N
        for j in 1:N
            y = f([xgrid[i, j], ygrid[i, j], 1])
                
            xgrid[i:i,j:j] = y[1]
            ygrid[i:i,j:j] = y[2]
            zgrid[i:i,j:j] = y[3]
        end
    end
end

function transform(f, X)
    N = size(X, 1)
    
    xd = zeros(N)
    yd = zeros(N)
    zd = zeros(N)
    
    for i in 1:N
        y = f([X[i, 1], X[i, 2], 1])
        
        xd[i] = y[1]
        yd[i] = y[2]
        zd[i] = y[3]
    end
    
    xd,yd,zd
end

function make_grammian(K, x, y)
    N = size(x, 1)
    Q = zeros(N, N)
    
    for i=1:N
        for j=1:i
            Q[i, j] = K(x[i, :], x[j, :]) * y[i] * y[j]
            Q[j, i] = Q[i, j]
        end
    end
    
    min_ev = eigmin(Q)
    if min_ev < 0
        Q - 2*min_ev .* I
    else
        Q
    end
end

function train_svm(data, labels; K=vecdot, tol=eps())
    N = size(data, 1)
    
    Q = make_grammian(K, data, labels)
    
    # compute α
    α = Variable(N, 1)
    
    problem = minimize(0.5*quadform(α, Q) - vecdot(α, ones(N)))
    problem.constraints += α >= 0
    problem.constraints += vecdot(α, labels) == 0

    solve!(problem, SCSSolver(verbose=false))
    α = α.value[:, 1]
    α = sparse(α)
    
    # compute w
    w = zeros(size(data, 2))
    for i = 1:N
        if α[i] > 0
            w += α[i] * labels[i] * data[i, :]
        end
    end
    
    # compute b
    b = 0
    for i = 1:N
        if α[i] > 0
            b = labels[i] - K(data[i, :], w)
            break
        end
    end
    
    w,b
end

function demo_1()
    X = readdlm("lin_points.txt")
    y = repeat([1; -1], inner=50)
    
    Xp, Xn = [X[:,1][y.==1] X[:,2][y.==1]], [X[:,1][y.==-1] X[:,2][y.==-1]]

    best_w, best_b = train_svm(X, y)
    
    @manipulate for α=linspace(pi/2, pi, 50),
                    b=linspace(.5, 1, 50),
                    showing=[
                        :none => 0,
                        :closest => 1,
                        :best => 2
                    ]
        withfig(fig) do
            xlim(-.5,1.5)
            ylim(-.5,1.5)
            axis("off")

            ax = gca()

            w = [-sin(α), cos(α)]
            
            if showing == 2
                w,b = best_w, best_b
            end
            
            v = [w[2], -w[1]]
            
            x₁ = -w * b/vecnorm(w)^2 + 10*v
            x₂ = -w * b/vecnorm(w)^2 - 10*v
            
            plot([x₁[1], x₂[1]], [x₁[2], x₂[2]],color="black",linewidth=0.7)

            scatter(X[:,1][y.==1], X[:,2][y.==1], marker="x", c="black")
            scatter(X[:,1][y.==-1], X[:,2][y.==-1], marker="o", edgecolor="black", facecolor=(0,0,0,0))        

            if showing > 0
                mps = [ abs(vecdot(Xp[i,:], w) + b)/vecnorm(w) for i=1:50]
                mp, ip = findmin(mps)
                
                xp = Xp[ip, :]
                xxp = xp - mp*w/vecnorm(w)
                plot([xp[1], xxp[1]], [xp[2], xxp[2]], linestyle="dashed", color="black", linewidth=1)


                mns = [ abs(vecdot(Xn[i,:], w) + b)/vecnorm(w) for i=1:50]
                mn, ineg = findmin(mns)
                xn = Xn[ineg, :]
                xxn = xn + mn*w/vecnorm(w)

                plot([xn[1], xxn[1]], [xn[2], xxn[2]], linestyle="dashed", color="black", linewidth=1)
            end
        end
    end;
end

function demo_2()
    N = 20
    xrange, yrange = linspace(-2, 2, N), linspace(-2, 2, N)

    f = (x) -> [x[1]^2, x[2]^2, sqrt(2)x[1]x[2]]
    X, y = two_cocentric();

    @manipulate for step=slider(1:20, value=1),
        showing=[:none => 0,
                 :space_boundary => 1,
                 :both => 2,
                 :intersection => 3
                 ]
        
        λ = linspace(0, 1, 20)[step]
        g = (x) -> (1 - λ) * x + λ * f(x)

        xgrid = repmat(xrange', N, 1)
        ygrid = repmat(yrange, 1, N)
        zgrid = zeros(N,N)

        xsep = repmat(xrange', N, 1) + .5
        ysep = -repmat(xrange', N, 1) + .5
        zsep = 2*repmat(yrange, 1, N)
        
        angles = repmat(linspace(-pi, pi, 20), 20, 2)
        xb,yb,zb = transform((x) -> g([cos(x[1]), sin(x[1]), 1]), angles)
        
        transform_grid!(g, xgrid, ygrid, zgrid)

        xd, yd, zd = transform(g, X)
        
        withfig(fig, clear=false) do
            cla()
            
            plt[:gca](projection="3d")[:_axis3don] = false
            mesh(xgrid, ygrid, zgrid, color="black", linestyles="dashed", linewidths=0.3)
            
            if showing == 1
                mesh(xsep, ysep, zsep, color="red", linestyles="dashed", linewidths=0.3)
            elseif showing == 2
                mesh(xsep, ysep, zsep, color="red", linestyles="dashed", linewidths=0.3)
                mesh(xb, yb, zb, color="red", linestyles="dashed", linewidths=0.3)
            elseif showing == 3
                mesh(xb, yb, zb, color="red", linestyles="dashed", linewidths=0.3)
            end
            
            scatter3D(xd[y.==1], yd[y.==1], zd[y.==1], marker=".")
            scatter3D(xd[y.==-1], yd[y.==-1], zd[y.==-1], marker="x")
        end
    end;
end
