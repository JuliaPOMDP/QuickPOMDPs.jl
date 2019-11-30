import julia
from julia.QuickPOMDPs import DiscreteExplicitPOMDP, QuickPOMDP
from julia.POMDPs import solve, pdf, states
from julia.QMDP import QMDPSolver
from julia.SARSOP import SARSOPSolver
from julia.POMDPPolicies import alphavectors, RandomPolicy
from julia.POMDPModelTools import Deterministic, SparseCat
from julia.POMDPSimulators import stepthrough, HistoryRecorder, eachstep, simulate
from julia import Base
from julia import Random

import pickle
import itertools
import copy
import time
import itertools
from collections import namedtuple
import typing
import random

class POMDPGenerator:
    def __init__(self, seed=1234):
        self.states = ['left', 'right']
        self.actions = ['left', 'right', 'listen']
        self.observations = ['left', 'right']
        
        self.rng = random.Random(seed)
        self.good_obs = .85
        self.init_state = .5
        self.random_obs = .5
  
    def initialstate_distribution(self):
        return SparseCat(self.states, [self.init_state, 1-self.init_state])
    
    def transition(self, s, a):
        if a == 'listen':
            sp = s
            return SparseCat([sp], [1.0])
        else: # a door is opened
            return self.initialstate_distribution()
        
    def transition2(self, s, a, sp):
        if a == 'listen':
            if sp == s:
                return 1.0
            else:
                return 0.0
        else: # a door is opened
            #d= self.initialstate_distribution()
            if sp=='left':
                return self.init_state
            else:
                return 1.0-self.init_state
        
    def observation(self, arg1, arg2, arg3=None):        
        if arg3 == None:
            return self.observation2(arg1, arg2)
        else:
            return self.observation2(arg2, arg3)
        
    def observation2(self, a, sp):
        if a == 'listen':
            if 'left' == sp:
                return SparseCat(['left', 'right'], [self.good_obs, 1.0-self.good_obs])
            else:
                return SparseCat(['left', 'right'], [1.0-self.good_obs, self.good_obs])
        else:
            return SparseCat(['left', 'right'], [self.random_obs, 1.0-self.random_obs])
        
    def observation3(self, a, sp, o):
        if a == 'listen':
            if o == sp:
                return self.good_obs
            else:
                return 1.0-self.good_obs
        else:
            if o == 'left':
                return self.random_obs
            else:
                return 1.0-self.random_obs

            
    def reward(self, s, a, sp=None, o=None):
        if a == 'listen':
            return -1.0
        elif s == a: # the tiger was found
            return -100.0
        else: # the tiger was escaped
            return 10.0
        
    def generate_pomdp(self, discount=0.95):
        
        return QuickPOMDP(
            initialstate_distribution = self.initialstate_distribution,
            transition = self.transition,
            observation = self.observation,
            reward=self.reward,
            states=self.states,
            actions=self.actions,
            observations=self.observations,
            discount=discount,
        )
    
    def generate_pomdp2(self, discount=0.95):
        
        return DiscreteExplicitPOMDP(
            self.states,
            self.actions,
            self.observations,
            self.transition2,
            self.observation3,
            self.reward,
            discount,
            self.initialstate_distribution(),
        )
    
    def isterminal(self, s):
        return s =='terminal'
    
    def generate_pomdp_with_terminal(self, discount=0.95):
        
        return QuickPOMDP(
            initialstate_distribution = self.initialstate_distribution,
            transition = self.transition,
            observation = self.observation,
            reward=self.reward,
            states=self.states + ['terminal'],
            actions=self.actions,
            observations=self.observations,
            discount=discount,
            isterminal=self.isterminal
        )
    
    def generate_pomdp_without_terminal(self, discount=0.95):
        
        return QuickPOMDP(
            initialstate_distribution = self.initialstate_distribution,
            transition = self.transition,
            observation = self.observation,
            reward=self.reward,
            states=self.states + ['terminal'],
            actions=self.actions,
            observations=self.observations,
            discount=discount,
        )

Gen = POMDPGenerator()
pomdp = Gen.generate_pomdp()

solver = SARSOPSolver()
policy = solve(solver, pomdp)

print('alpha vectors:')
for v in alphavectors(policy):
    print(v)

print()

for step in stepthrough(pomdp, policy, "s,a,o", max_steps=10):
    print(step.s)
    print(step.a)
    print(step.o)
    print()

Gen = POMDPGenerator()
pomdp = Gen.generate_pomdp_with_terminal()
policy = RandomPolicy(pomdp)
for step in stepthrough(pomdp, policy, "s,a,o", max_steps=10):
    print(step.s)
    print(step.a)
    print(step.o)
    print()
