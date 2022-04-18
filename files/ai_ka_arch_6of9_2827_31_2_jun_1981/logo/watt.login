
..genjfl/0
..belcnt/1
..sendrp/0
..clobrf/1
..c.zprt/0
..delwarn/2

:ddtsym ttynum/
:if e q-31
(:jump atari
)

:ddtsym ttynum/
:if e q-33
(:jump atari
)
:jump end

:tag atari
:tctyp soft hei 24 wid 39 +%tosai +%tolid +%tocid full +%tprsc no overwrite
:ttyloc Logo 327

:tag end
:intest
:vk
