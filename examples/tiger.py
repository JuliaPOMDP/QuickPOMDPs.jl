# Tiger POMDP from Kaelbling et al. 98 (http://www.sciencedirect.com/science/article/pii/S000437029800023X)

from julia.QuickPOMDPs import *
from julia.POMDPs import solve, pdf
from julia.QMDP import QMDPSolver
from julia.POMDPSimulators import stepthrough
from julia.POMDPPolicies import alphavectors

S = ['left', 'right']
A = ['left', 'right', 'listen']
O = ['left', 'right']
γ = 0.95

def T(s, a, sp):
    if a == 'listen':
        return s == sp
    else: # a door is opened
        return 0.5 #reset

def Z(a, sp, o):
    if a == 'listen':
        if o == sp:
            return 0.85
        else:
            return 0.15
    else:
        return 0.5

def R(s, a):
    if a == 'listen':
        return -1.0
    elif s == a: # the tiger was found
        return -100.0
    else: # the tiger was escaped
        return 10.0

m = DiscreteExplicitPOMDP(S,A,O,T,Z,R,γ)

solver = QMDPSolver()
policy = solve(solver, m)

print('alpha vectors:')
for v in alphavectors(policy):
    print(v)

print()

rsum = 0.0
for step in stepthrough(m, policy, max_steps=10):
    print('s:', step.s)
    print('b:', [pdf(step.b, x) for x in S])
    print('a:', step.a)
    print('o:', step.o, '\n')
    rsum += step.r

print('Undiscounted reward was', rsum)
