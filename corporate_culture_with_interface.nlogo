;;;; SETTING VARIABLES ;;;;

globals [
  ;; values
  NULL_EFFORT_VALUE
  HIGH_EFFORT_VALUE

  ;; agent types
  NULL_EFFORT
  SHRINKING_EFFORT
  REPLICATOR
  RATIONAL
  PROFIT_COMPARATOR
  HIGH_EFFORT
  AVERAGE_RATIONAL
  WINNER_IMITATOR
  EFFORT_COMPARATOR
  AVERAGER

  ;; to plot
  average-effort
]

turtles-own [
  ;; agent attributes (cf. class Agent in section 5.1)
  _type
  dir
  step
  colt
  evol
  numinc
  effort
  profit
  cumprof
  leffort
  cumeffort
  lprofit
  aeffort
  aprofit
  neffort
  nprofit
]

;;;;;;;;;;;;;;;;;;;;;;;;;



;;;; MAIN PROCEDURES ;;;;

to go
  if ticks = max-nb-ticks [ stop ]
  move-agents
  game
  set average-effort mean [effort] of turtles
  tick
end

to setup
  clear-all
  setup-globals
  setup-turtles
  reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;;;;;



;;;; INITIALISATION ;;;;

to setup-globals
  ;; values
  set NULL_EFFORT_VALUE 0.0001
  set HIGH_EFFORT_VALUE 2.0

  ;; agent types
  set NULL_EFFORT 0
  set SHRINKING_EFFORT 1
  set REPLICATOR 2
  set RATIONAL 3
  set PROFIT_COMPARATOR 4
  set HIGH_EFFORT 5
  set AVERAGE_RATIONAL 6
  set WINNER_IMITATOR 7
  set EFFORT_COMPARATOR 8
  set AVERAGER 9
end

to setup-turtles
  create-turtles total-nb-agents    ; uses the value of the number slider to create turtles
  init-type
  init-pos
  init-efforts
  init-col
  rand-dir
end

to init-pos
  ask turtles [
    setxy (floor random-xcor) (floor random-ycor)
    while [count turtles-here >= 2] [ ; to make sure turtle appear in different coordinates
      setxy (floor random-xcor) (floor random-ycor)
    ]
  ]
end

to init-efforts
  ask turtles [
    set effort NULL_EFFORT + random-float (HIGH_EFFORT_VALUE - NULL_EFFORT_VALUE) ; random for all turtles (at first), between null effort and high effort
    if _type = NULL_EFFORT [set effort NULL_EFFORT_VALUE] ; null effort agent
    if (_type = HIGH_EFFORT or _type = WINNER_IMITATOR) [set effort HIGH_EFFORT_VALUE] ; high effort agent and winner imitator start with high effort
  ]
end

to init-type
  ask turtles [set _type random 10] ; type is random by default

  ;; init for the case we are trying to look for equilibriums (cf. question 3.1)
  if all-agents-same-type or all-same-type-but-one [
    ask turtles [set _type majority-type]
  ]
  if all-same-type-but-one [
    ask turtle 0 [set _type only-one-agent-this-type]
  ]

  ;; init to reproduce Fig 6.
  if high-effort-in-population [
    let nb-high-eff floor ((prop-high-eff / 100) * total-nb-agents)
    ask turtles [
      ifelse who < nb-high-eff [set _type HIGH_EFFORT] [set _type population-type]
    ]
  ]
end

to init-col
  ask turtles [ set color (10 * _type + 15)  ] ; arbitrary coloring of types to fit with Netlogo scale
end

;;;;;;;;;;;;;;;;;;;;;;;;;



;;;; MOVING PROCEDURES ;;;;

to rand-dir ;; changes direction at random
  ask turtles [
    set dir (random 4)
    set heading dir * 90
  ]
end

to move-agents
  rand-dir
  ask turtles [if not any? turtles-on patch-ahead 1 [fd 1]] ;; constraint of not having more than one agent per cell
end

;;;;;;;;;;;;;;;;;;;;;;;;;



;;;; FIGURING OUT IF AGENTS SHOULD COOPERATE & THE PROFIT ;;;;

to-report _profit [e_i e_j]
  report 5 * sqrt(e_i + e_j) - e_i * e_i
end

;; main loop where agents cooperate to do a task if they are facing each other
to game
  ask turtles [
    ;set label floor(10000 * effort) / 10000 ; to see efforts up to the 1e-4 precision
    let agent_1 self
    let heading_1 heading
    let effort_1 effort
    if any? turtles-on patch-ahead 1 [
      ask turtles-on patch-ahead 1 [
        let heading_2 heading
        let agent_2 self
        let effort_2 effort
        if (heading_1 != heading_2) and ((heading_1 + heading_2) mod 180 = 0) [
          let profit_1 _profit effort_1 effort_2
          let profit_2 _profit effort_2 effort_1
          update_attr agent_1 effort_1 effort_2 profit_1 profit_2
          update_effort agent_1 ; updating effort for agent 1 because agent 2 will already be updated in the outer loop
        ]
      ]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;



;;;; FIGURING OUT HOW TO UPDATE EFFORTS & ATTRIBUTES ;;;;

;; updates attributes of the agent, using profits and efforts from agent and antagonist
;; "ant" is for antagonist
to update_attr [agent eff_ag eff_ant prof_ag prof_ant]
  ask agent [
    set numinc (numinc + 1)
    set lprofit profit
    set leffort effort
    set aeffort eff_ant
    set aprofit prof_ant
    set profit prof_ag
    set cumprof (cumprof + profit)
  ]
end

;; update next effort to do, depending on type
to update_effort [agent]
  ask agent [
    let tmp new-effort effort aeffort profit aprofit cumeffort
    set effort (max list tmp NULL_EFFORT_VALUE) ; we want efforts to be above 1e-4
  ]
end

to-report new-effort [eff_ag eff_ant prof_ag prof_ant cumeffort_part]
  if _type = NULL_EFFORT [report NULL_EFFORT_VALUE]
  if _type = SHRINKING_EFFORT [report eff_ant / 2]
  if _type = REPLICATOR [report eff_ant]
  if _type = RATIONAL [report rational-eff eff_ant]
  if _type = PROFIT_COMPARATOR [report profit-comparator eff_ag prof_ag prof_ant]
  if _type = HIGH_EFFORT [report HIGH_EFFORT_VALUE]
  if _type = AVERAGE_RATIONAL [report rational-eff eff_ag]
  if _type = WINNER_IMITATOR [report winner-imitator eff_ag eff_ant prof_ag prof_ant]
  if _type = EFFORT_COMPARATOR [report effort-comparator eff_ag eff_ant]
  if _type = AVERAGER [report average eff_ag eff_ant]
end

to-report rational-eff [eff]
  ;; when we try to find the zero of the derivative of the profit (for the rational answer) we get to solve a cubic equation
  report find-max-root-cubic 1 eff 0 (1.5625) ; cf. pdf report for where this 1.5625 come from
end

;; we use the solutions provided in "Trigonometric and hyperbolic solutions" here: https://en.wikipedia.org/wiki/Cubic_function#Trigonometric_solution_for_three_real_roots
to-report find-max-root-cubic [a b c d] ; find maximum real root of cubic ax^3 + bx^2 + cx + d (cf.
  let p (3 * a * c - b ^ 2) / (3 * a ^ 2)
  let q (2 * b ^ 3 - 9 * a * b * c + 27 * a ^ 2 * d) / (27 * a ^ 3)
  ifelse 4 * p ^ 3 + 27 * q ^ 2 <= 0
  [report 2 * sqrt (- p / 3) * cos ((1 / 3) * acos ((3 * q * sqrt (- 3 / p)) / (2 * p)))]
  [report -2 / (abs (q) / q) * sqrt (- p / 3) * cosh ((1 / 3) * arcosh (-(3 * (abs q) * sqrt (- 3 / p)) / (2 * p)))]
end

to-report profit-comparator [eff prof_ag prof_ant]
  ifelse prof_ag >= prof_ant [report 1.1 * eff] [report 0.9 * eff]
end

to-report effort-comparator [eff_ag eff_ant]
  ifelse eff_ag >= eff_ant [report 1.1 * eff_ag] [report 0.9 * eff_ant]
end

to-report winner-imitator [eff_ag eff_ant prof_ag prof_ant]
  ifelse prof_ag >= prof_ant [report eff_ag] [report eff_ant]
end

to-report average [eff_ag eff_ant]
  report (eff_ag + eff_ant) / 2
end

;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; AUXILIARY MATH FUNCTIONS FOR SOLVING THE CUBIC EQUATION ;;;;

to-report arsinh [x]
  report ln (x + sqrt (x * x + 1))
end

to-report arcosh [x]
  report ln (x + sqrt (x * x - 1))
end

to-report cosh [x]
  report (e ^ x + e ^ (- x)) / 2
end

to-report sinh [x]
  report (e ^ x - e ^ (- x)) / 2
end

;;;;;;;;;;;;;;;;;;;;;;;;;
@#$#@#$#@
GRAPHICS-WINDOW
218
31
630
444
-1
-1
4.0
1
10
1
1
1
0
1
1
1
0
100
0
100
1
1
1
ticks
1.0

BUTTON
319
458
395
513
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
219
459
298
513
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
34
35
208
68
total-nb-agents
total-nb-agents
0
10000
3800.0
100
1
(agents)
HORIZONTAL

SWITCH
31
143
205
176
all-agents-same-type
all-agents-same-type
0
1
-1000

SWITCH
30
179
205
212
all-same-type-but-one
all-same-type-but-one
1
1
-1000

SLIDER
30
218
205
251
majority-type
majority-type
0
9
1.0
1
1
NIL
HORIZONTAL

SLIDER
30
256
205
289
only-one-agent-this-type
only-one-agent-this-type
0
10
1.0
1
1
NIL
HORIZONTAL

SWITCH
28
338
202
371
high-effort-in-population
high-effort-in-population
1
1
-1000

SLIDER
28
377
202
410
prop-high-eff
prop-high-eff
0
100
0.6
1
1
% agents
HORIZONTAL

TEXTBOX
32
120
180
139
Finding equilibriums
14
0.0
0

SLIDER
28
414
202
447
population-type
population-type
0
9
0.0
1
1
NIL
HORIZONTAL

TEXTBOX
29
315
204
333
Reproducing Fig 6 & 7
14
0.0
0

TEXTBOX
35
10
185
29
[ PARAMETERS ]
15
0.0
1

TEXTBOX
665
12
815
31
[ RESULTS ]
15
0.0
1

MONITOR
665
35
768
80
NIL
average-effort
5
1
11

SLIDER
34
74
208
107
max-nb-ticks
max-nb-ticks
0
10000
10000.0
100
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
