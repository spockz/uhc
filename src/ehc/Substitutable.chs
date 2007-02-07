%%[0
%include lhs2TeX.fmt
%include afp.fmt

%if style == poly
%format sl1
%format sl1'
%format sl2
%format sl2'
%endif
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Substitution for types
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[2 module {%{EH}Substitutable} import(Data.List, {%{EH}Base.Common}, {%{EH}Ty}, {%{EH}Cnstr},{%{EH}Ty.Subst},{%{EH}Ty.Ftv}) export(Substitutable(..))
%%]

%%[4_2 export((|>>))
%%]

%%[9 import(qualified Data.Map as Map) export(fixTyVarsCnstr,tyFixTyVars)
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Substitutable class
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[2.Substitutable
infixr 6 |=>
%%]

%%[2.Substitutable
class Substitutable k v vv | vv -> v k where
  (|=>)         ::  Cnstr' k v -> vv -> vv
  ftv           ::  vv -> [k]
%%]

%%[9.Substitutable -2.Substitutable
class Substitutable k v vv | vv -> v k where
  (|=>)         ::  Cnstr' k v -> vv -> vv
  ftv           ::  vv -> [k]
%%]

%%[4_2.partialSubstApp
infixr 6 |>>

(|>>) :: Cnstr -> Cnstr -> Cnstr
c1 |>> c2 = cnstrMapTy (const (c1 |=>)) c2
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Substitutable instances
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[2.SubstitutableTy
instance Substitutable TyVarId Ty Ty where
  (|=>)  = tyAppCnstr
  ftv    = tyFtv
%%]

%%[9.SubstitutableTy -2.SubstitutableTy
instance Substitutable TyVarId (CnstrInfo Ty) Ty where
  (|=>)  = tyAppCnstr
  ftv    = tyFtv
%%]

%%[2.SubstitutableList
instance (Ord k,Substitutable k v vv) => Substitutable k v [vv] where
  s      |=>  l   =   map (s |=>) l
  ftv         l   =   unions . map ftv $ l
%%]

%%[2.SubstitutableCnstr
instance (Ord k,Substitutable k v v) => Substitutable k v (Cnstr' k v) where
  s1@(Cnstr sl1) |=> s2@(Cnstr sl2)
    = Cnstr (sl1 ++ map (\(v,t) -> (v,s1 |=> t)) sl2')
    where sl2' = deleteFirstsBy (\(v1,_) (v2,_) -> v1 == v2) sl2 sl1
  ftv (Cnstr sl)
    = ftv . map snd $ sl
%%]

%%[7
instance Substitutable k v vv => Substitutable k v (HsName,vv) where
  s |=>  (k,v) =  (k,s |=> v)
  ftv    (_,v) =  ftv v
%%]

%%[9.SubstitutableCnstr -2.SubstitutableCnstr
instance (Ord k,Substitutable k v v) => Substitutable k v (Cnstr' k v) where
  s1@(Cnstr sl1) |=>   s2@(Cnstr sl2)  =   Cnstr (sl1 `Map.union` Map.map (s1 |=>) sl2)
  ftv                  (Cnstr sl)      =   ftv . Map.elems $ sl
%%]

%%[9
instance Substitutable TyVarId (CnstrInfo Ty) Pred where
  s |=>  p  =  (\(Ty_Pred p) -> p) (s |=> (Ty_Pred p))
  ftv    p  =  ftv (Ty_Pred p)

instance Substitutable TyVarId (CnstrInfo Ty) PredOcc where
  s |=>  (PredOcc pr id)  = PredOcc (tyPred (s |=> Ty_Pred pr)) id
  ftv    (PredOcc pr _)   = ftv (Ty_Pred pr)

instance Substitutable TyVarId (CnstrInfo Ty) Impls where
  s |=>  i  =  (\(Ty_Impls i) -> i) (s |=> (Ty_Impls i))
  ftv    i  =  ftv (Ty_Impls i)

instance Substitutable TyVarId (CnstrInfo Ty) (CnstrInfo Ty) where
  s |=>  ci =  case ci of
                 CITy     t -> CITy (s |=> t)
                 CIImpls  i -> CIImpls (s |=> i)
  ftv    ci =  case ci of
                 CITy     t -> ftv t
                 CIImpls  i -> ftv i
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Fixating free type vars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[9
fixTyVarsCnstr :: Ty -> Cnstr
fixTyVarsCnstr = Cnstr . Map.fromList . map (\v -> (v,CITy (Ty_Var v TyVarCateg_Fixed))) . ftv

tyFixTyVars :: Ty -> Ty
tyFixTyVars s = fixTyVarsCnstr s |=> s
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Tvar under constr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[4_1 hs
%%]
tvUnderCnstr :: Cnstr -> TyVarId -> TyVarId
tvUnderCnstr c v
  =  case c |=> mkTyVar v of
		Ty_Var   v' TyVarCateg_Plain  -> v'
		Ty_Alts  v' _                 -> v'
		_                             -> v

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Are tvars alpha renaming of eachother?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[4_1 hs
%%]
tvLMbAlphaRename :: Cnstr -> TyVarIdL -> TyVarIdL -> Maybe TyVarIdL
tvLMbAlphaRename c l1 l2
  =  if l1' == l2' && length l1' == length l1 then Just l1' else Nothing
  where  r = sort . nub . map (tvUnderCnstr c)
         l1' = r l1
         l2' = r l2
