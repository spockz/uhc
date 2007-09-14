%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Deriving info
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[95 module {%{EH}Deriving} import({%{EH}Base.Builtin},{%{EH}Base.Common},{%{EH}Base.Opts},{%{EH}Gam},{%{EH}Ty},{%{EH}Core},{%{EH}Core.Utils})
%%]

%%[95 import(qualified Data.Map as Map,Data.List,EH.Util.Utils)
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Table for each derivable field of each derivable class: type as well as codegen info
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[95 export(DerivClsFld(..),DerivClsMp)
data DerivClsFld
  = DerivClsFld
      { dcfNm                       :: !HsName                                  -- name of field
      , dcfTy                       :: !Ty                                      -- type of field
      , dcfMkCPat                   ::                                          -- make the pattern for each alternative
                                       Int                                      -- index of alternative (the actual Enum ordering)
                                       -> CTag                                  -- tag
                                       -> Int                                   -- arity
                                       -> Maybe [HsName]                        -- optional list of names for constituents
                                       -> CPat
      , dcfInitialArgL              :: ![HsName]                                -- initial arguments for function, passed to dcfFoldSubsCExpr
      , dcfInitialSubArgL           :: DataTagInfo -> [CExpr]                   -- initial arguments for constituents
      , dcfNrOmitTailArg            :: !Int                                     -- nr of args not passed, i.e. how much to omit for partial app
      , dcfFoldSubsCExpr            :: UID                                      -- construct out of constituents
                                       -> RCEEnv
                                       -> DataTagInfo                           -- this tag info
                                       -> (Int,Int)                             -- (index (a la toEnum), nr of alts)
                                       -> [HsName]                              -- names of initial args (usually same as dcfInitialArgL)
                                       -> [CExpr]                               -- constituents
                                       -> CExpr
      , dcfNoArgSubsCExpr           :: [(DataTagInfo,[CExpr])]                  -- all tag info + subs
                                       -> CExpr                                 -- when class member takes no args
      , dcfAllTagLtCExpr            :: !CExpr                                   -- when tags are < previous
      , dcfAllTagGtCExpr            :: !CExpr                                   -- when tags are > previous
      , dcfWrapCase                 :: 											-- wrap case expr in derived function
                                       EHCOpts
      								   -> DataGamInfo							-- info of data ty
                                       -> Int                                   -- nr of alts
      								   -> HsName								-- name of expr inspected by case expr
      								   -> CExpr									-- case expr
      								   -> CExpr
      }

type DerivClsMp = Map.Map HsName (AssocL HsName DerivClsFld)
%%]

The table is dependent on builtin names, stored in EHCOpts.

%%[95 export(mkDerivClsMp)
mkDerivClsMp :: EHCOpts -> ValGam -> DataGam -> DerivClsMp
mkDerivClsMp opts valGam dataGam
  = Map.unionsWith (++)
    $ map (uncurry Map.singleton) 
    $ [
      -- Eq((==))
        mk ehbnClassEq ehbnClassEqFldEq
           (const mkCPatCon)
           []
           (const [])
           0
           (\_ _ _ _ _ vs
                -> case vs of
                     [] -> true
                     _  -> foldr1 and vs
           )
           (const undef)
           false false
           nowrap
      
      -- Ord(compare)
      , mk ehbnClassOrd ehbnClassOrdFldCompare
           (const mkCPatCon)
           []
           (const [])
           0
           (\uniq env _ _ _ vs
                -> case vs of
                     [] -> eq
                     _  -> foldr1 (\l r -> mkCExprStrictSatCase env (Just nStrict) l
                                             [ CAlt_Alt (mkCPatCon (orderingTag eqNm) 0 Nothing) r
                                             , CAlt_Alt (mkCPatCon (orderingTag ltNm) 0 Nothing) lt
                                             , CAlt_Alt (mkCPatCon (orderingTag gtNm) 0 Nothing) gt
                                             ]
                                  ) vs
                        where n = mkHNm uniq
                              nStrict = hsnSuffix n "!"
           )
           (const undef)
           gt lt
           nowrap
      
      -- Enum(fromEnum,succ,pred)
      , mk ehbnClassEnum ehbnClassEnumFldFromEnum
           (const mkCPatCon)
           []
           (const [])
           0
           (\_ env _ (altInx,_) _ []
                -> CExpr_Int altInx
           )
           (const undef)
           undef undef
           nowrap
      , mk ehbnClassEnum ehbnClassEnumFldToEnum
           (\altInx _ _ _ -> CPat_Int hsnWild altInx)
           []
           (const [])
           0
           (\_ _ dti _ _ []
                -> CExpr_Tup (dtiCTag dti)
           )
           (const undef)
           undef undef
           (\opts dgi nrOfAlts cNm body
             -> let cNmv = CExpr_Var cNm
                    cNm1 = hsnSuffix cNm "!boundCheck"
                in  mkCIf opts (Just cNm1)
                      (cbuiltinApp opts ehbnPrimGtInt [cNmv,CExpr_Int (nrOfAlts-1)])
                      (cerror opts $ "too high for toEnum to " ++ show (dgiTyNm dgi))
                      (mkCIf opts (Just cNm1)
                        (cbuiltinApp opts ehbnPrimGtInt [CExpr_Int 0,cNmv])
                        (cerror opts $ "too low for toEnum to " ++ show (dgiTyNm dgi))
                        body
                      )
           )
      , mk ehbnClassEnum ehbnClassEnumFldSucc
           (const mkCPatCon)
           []
           (const [])
           0
           (\_ env dti (altInx,nrOfAlts) _ []
                -> if altInx < nrOfAlts  - 1
                   then CExpr_Int $ altInx + 1
                   else cerror opts $ "cannot succ last constructor: " ++ show (dtiConNm dti)
           )
           (const undef)
           undef undef
           nowrap
      , mk ehbnClassEnum ehbnClassEnumFldPred
           (const mkCPatCon)
           []
           (const [])
           0
           (\_ env dti (altInx,_) _ []
                -> if altInx > 0
                   then CExpr_Int $ altInx - 1
                   else cerror opts $ "cannot pred first constructor: " ++ show (dtiConNm dti)
           )
           (const undef)
           undef undef
           nowrap
      
      -- Bounded(maxBound,minBound)
      , mk ehbnClassBounded ehbnClassBoundedFldMaxBound
           (const mkCPatCon)
           []
           (const [])
           0
           (\_ _ _ _ _ _
                -> undef
           )
           (\dtiSubs
                -> let (dti,subs) = last dtiSubs
                   in  CExpr_Tup (dtiCTag dti) `mkCExprApp` subs
           )
           undef undef
           nowrap
      , mk ehbnClassBounded ehbnClassBoundedFldMinBound
           (const mkCPatCon)
           []
           (const [])
           0
           (\_ _ _ _ _ _
                -> undef
           )
           (\dtiSubs
                -> let (dti,subs) = head dtiSubs
                   in  CExpr_Tup (dtiCTag dti) `mkCExprApp` subs
           )
           undef undef
           nowrap
      
      -- Show(showsPrec)
      , mk ehbnClassShow ehbnClassShowFldShowsPrec
           (const mkCPatCon)
           [precDepthNm]
           (\dti -> [CExpr_Int $ maybe (fixityMaxPrio + 1) (+1) $ dtiMbFixityPrio $ dti])
           0
           (\_ _ dti _ [dNm] vs
                -> let mk needParen v = mkCExprApp (CExpr_Var $ fn ehbnPrelShowParen) [needParen,v]
                   in  case (vs,dtiMbFixityPrio dti) of
                         ([],_)
                           -> showString $ tag2str (dtiCTag dti)
                         ([v1,v2],Just p)
                           -> mk (cgtint opts (CExpr_Var dNm) p)
                              $ foldr1 compose ([v1] ++ [ showString $ " " ++ tag2str (dtiCTag dti) ++ " " ] ++ [v2])
                         _ -> mk (cgtint opts (CExpr_Var dNm) fixityMaxPrio)
                              $ foldr1 compose ([showString $ tag2str (dtiCTag dti) ++ " "] ++ intersperse (showString " ") vs)
           )
           (const undef)
           undef undef
           nowrap
      ]
  where mk c f mkPat as asSubs omTl cAllMatch cNoArg cLT cGT wrap
          = (c', [mkf f])
          where c' = fn c
                mkf f = (f', DerivClsFld f' t mkPat as asSubs omTl cAllMatch cNoArg cLT cGT wrap)
                      where f' = fn f
                            (t,_) = valGamLookupTy f' valGam
        fn f  = f $ ehcOptBuiltinNames opts
        false = CExpr_Var $ fn ehbnBoolFalse
        true  = CExpr_Var $ fn ehbnBoolTrue
        and l r = (CExpr_Var $ fn ehbnBoolAnd) `mkCExprApp` [l,r]
        compose l r = (CExpr_Var $ fn ehbnPrelCompose) `mkCExprApp` [l,r]
        showString s = (CExpr_Var $ fn ehbnPrelShowString) `mkCExprApp` [cstring opts s]
        eqNm = fn ehbnDataOrderingAltEQ
        ltNm = fn ehbnDataOrderingAltLT
        gtNm = fn ehbnDataOrderingAltGT
        eq = CExpr_Var eqNm
        lt = CExpr_Var ltNm
        gt = CExpr_Var gtNm
        precDepthNm = mkHNm "d"
        undef = cundefined opts
        tag2str = show . hsnQualified . ctagNm
        orderingTag conNm
          = dtiCTag
            $ dgiDtiOfCon conNm
            $ panicJust "mkDerivClsMp.dataGamLookup"
            $ dataGamLookup (fn ehbnDataOrdering) dataGam
        nowrap _ _ _ _ x = x
%%]

                in  mkCIf opts (Just cNm1)
                      (mkCExprStrictIn cNm2 (CExpr_Var cNm)
                         (\v -> cbuiltinApp opts ehbnBoolOr
                                 [ cbuiltinApp opts ehbnPrimGtInt [v,CExpr_Int (nrOfAlts-1)]
                                 , cbuiltinApp opts ehbnPrimGtInt [CExpr_Int 0,v]
                                 ]
                      )  )
                      (cerror opts $ "out of bounds for toEnum to " ++ show (dgiTyNm dgi))
                      body