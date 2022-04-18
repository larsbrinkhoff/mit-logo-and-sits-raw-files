
:SELF
    PROMPT/ 7TYPE VPATCH
    VPATCH/ 0"> 
    BYERUN/ -1
    C.ZPRT/ -1
    GENJFL/ -1
    SNDFLG/ -1
    CLOBRF/ 0
    CONFRM/ 0
   MORWARN/ 0
    BELCNT/ 1
    CKQFLG/ 1
   DELWARN/ 1
     LINKP/ 1
    MASSCP/ 1
    SMLINS/ 1
    TCTYP/
:KILL
   :IF E Q-%TNSFW
       (:[Soft TTY]TERPRI
       )
   :ELSE
       (:--DM2500--IF MORE 0
             (:TCTYP DM2500
               :CLEAR 
             )
         :ELSE
             (:TERPRI
               :Terminal? INLINE :TCTYP
             )
       )
   :--Fast--IF MORE 0
       (:INFLS 
       )
   :TERPRI
   :--OddLoc--IF MORE 0
       (:TERPRI
         :Where? INLINE :TTYLOC
       )
   :ELSE
       (:TTYLOC  Waiting...
         :TERPRI
       )
   :IF E :JOBP ARGUS
      >(:[Woof]FORGET
       )
   :ELSE
       (:--Argus--IF MORE 0
             (:ARGUS JHH,Turner,Gren,Klotz,RMS,EH,KJB
             )
       )
   :TERPRI
   :IF E :EXISTS LEADER MAIL NLOGO;
      >(:--Mail--IF MORE 0
             (:NBABYL
               :CLEAR 
             )
         :ELSE
             (:PostponedTERPRI
             )
       )
   :ELSE
       (:[No mail]TERPRI
       )
:DSKUSE %
         :FIND NLOGO;&TODAY &SIZE > 0 /BRIEF 
       )
   :ELSE
       (
       )
   :TERPRI
:TERPRI
   :JOBS
   :TERPRI
:VK
