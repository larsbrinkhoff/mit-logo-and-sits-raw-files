..GENJFL/1
..dirfn1/ 1'cdate
..dirfn1+1/ 1'down
:ddtsym tygtyp/
:if n q&10000 > (
:ddtsym ttynum/
:if n q&1 > (:bee;pict1
)
:if e q&1 > (:bee;pict
)
:ddtsym tygtyp/
:tctype tv,sail,wholine 1
)
:if n q&20000 > (:tctyp glass
)
:GMSGS RJL/N
:IF N :EXISTS rjl;RJL MAIL
>(
:NO MAIL

)
:IF E :EXISTS rjl;RJL MAIL
>(
:e mm rmail
)
