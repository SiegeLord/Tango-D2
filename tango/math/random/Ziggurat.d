/*******************************************************************************
        copyright:      Copyright (c) 2008. Fawzi Mohamed
        license:        BSD style: $(LICENSE)
        version:        Initial release: July 2008
        author:         Fawzi Mohamed
*******************************************************************************/
module tango.math.random.Ziggurat;
import tango.math.Bracket:findRoot;
import tango.math.Math:abs;
import tango.math.ErrorFunction:erfc;

// ----- templateFu begin --------
/// is T is a real floating point number
template isReal(T){
    const isReal=is(T==float)||is(T==double)||is(T==real);
}
/// if T is a complex number
template isComplex(T){
    const isComplex=is(T==cfloat)||is(T==creal)||is(T==cdouble);
}

/// if T is a purely imaginary number
template isImaginary(T){
    const isImaginary=is(T==ifloat)|| is(T==idouble)|| is(T==ireal);
}

/// Strips the []'s off of a type.
template arrayBaseT(T)
{
    static if( is( T S : S[]) ) {
        alias arrayBaseT!(S)  arrayBaseT;
    }
    else {
        alias T arrayBaseT;
    }
}
// ----- templateFu end --------

/// ziggurat method for decreasing distributions.
/// Marsaglia, Tsang, Journal of Statistical Software, 2000
/// If has negative is true the distribution is assumed to be symmetric with respect to 0, 
/// otherwise it is assumed to be from 0 to infinity.
/// Struct based to avoid extra indirection when wrapped in a class (and it should be wrapped
/// in a class and not used directly).
/// Call style initialization avoided on purpose (this is a big structure, you don't want to return it)
struct Ziggurat(RandG,T,alias probDensityF,alias tailGenerator,bool hasNegative=true){
    static assert(isReal!(T),T.stringof~" not acceptable, only floating point variables supported");
    const int nBlocks=256;
    T[nBlocks+1] posBlock;
    T[nBlocks+1] fVal;
    RandG r;
    alias Ziggurat SourceT;
    /// initializes the ziggurat
    static Ziggurat create(alias invProbDensityF, alias cumProbDensityFCompl)(RandG rGenerator,real xLast=-1.0L,bool check_error=true){
        /// function to find xLast
        real findXLast(real xLast){
            real v=xLast*probDensityF(xLast)+cumProbDensityFCompl(xLast);
            real fMax=probDensityF(0.0L);
            real pAtt=xLast;
            real fAtt=probDensityF(xLast);
            for (int i=nBlocks-2;i!=0;--i){
                fAtt+=v/pAtt;
                if (fAtt>fMax) return fAtt+(i-1)*fMax;
                pAtt=invProbDensityF(fAtt);
                assert(pAtt>=0,"invProbDensityF is supposed to return positive values");
            }
            return fAtt+v/pAtt-fMax;
        }
        void findBracket(ref real xMin,ref real xMax){
            real vMin=cumProbDensityFCompl(0.0L)/nBlocks;
            real pAtt=0.0L;
            for (int i=1;i<nBlocks;++i){
                pAtt+=vMin/probDensityF(pAtt);
            }
            real df=findXLast(pAtt);
            if (df>0) {
                // (most likely)
                xMin=pAtt;
                real vMax=cumProbDensityFCompl(0.0L);
                xMax=pAtt+vMax/probDensityF(pAtt);
            } else {
                xMax=pAtt;
                xMin=vMin/probDensityF(0.0L);
            }
        }
        if (xLast<=0){
            real xMin,xMax;
            findBracket(xMin,xMax);
            xLast=findRoot(&findXLast,xMin,xMax);
            // printf("xLast:%La => %La\n",xLast,findXLast(xLast));
        }
        Ziggurat res;
        with (res){
            r=rGenerator;
            real v=probDensityF(xLast)*xLast+cumProbDensityFCompl(xLast);
            real pAtt=xLast;
            real fMax=probDensityF(0.0L);
            posBlock[1]=cast(T)xLast;
            real fAtt=probDensityF(xLast);
            fVal[1]=cast(T)fAtt;
            for (int i=2;i<nBlocks;++i){
                fAtt+=v/pAtt;
                assert(fAtt<=fMax,"Ziggurat contruction shoot out");
                pAtt=invProbDensityF(fAtt);
                assert(pAtt>=0,"invProbDensityF is supposed to return positive values");
                posBlock[i]=cast(T)pAtt;
                fVal[i]=cast(T)fAtt;
            }
            posBlock[nBlocks]=0.0L;
            fVal[nBlocks]=cast(T)probDensityF(0.0L);
            real error=fAtt+v/pAtt-probDensityF(0.0L);
            assert((!check_error) || error<real.epsilon*10000.0,"Ziggurat error larger than expected");
            posBlock[0]=cast(T)(xLast*(1.0L+cumProbDensityFCompl(xLast)/probDensityF(xLast)));
            fVal[0]=0.0L;
            for (int i=0;i<nBlocks;++i){
                assert(posBlock[i]>=posBlock[i+1],"decresing posBlock");
                assert(fVal[i]<=fVal[i+1],"increasing probabilty density function");
            }
        }
        return res;
    }
    /// returns a single value with the probability distribution of the current Ziggurat
    T getRandom() 
    {
        static if (hasNegative){
            for (int iter=1000;iter!=0;--iter) 
            { 
                uint i=r.uniform!(ubyte);
                T u = r.uniformRSymm!(T)(1);
                T x = posBlock[i]*u;
                if (abs(x)<posBlock[i+1]) return x;
                if (i == 0) return tailGenerator(r,posBlock[1],x<0);
                if ((cast(T)probDensityF(x))>fVal[i+1]+(fVal[i]-fVal[i+1])*r.uniform!(T)) {
                    return x;
                }
            }
        } else {
            for (int iter=1000;iter!=0;--iter) 
            { 
                uint i=r.uniform!(ubyte);
                T u = r.uniform!(T)();
                T x = posBlock[i]*u;
                if (x<posBlock[i+1]) return x;
                if (i == 0) return tailGenerator(r,posBlock[1]);
                if ((cast(T)probDensityF(x))>fVal[i+1]+(fVal[i]-fVal[i+1])*r.uniform!(T)) {
                    return x;
                }
            }
        }
        throw new Exception("max nr of iterations in Ziggurat, this should have probability<1.0e-1000");
    }
    /// initializes the argument with the probability distribution given and returns it
    /// for arrays this might potentially be faster than a naive loop
    U randomize(U)(ref U a){
        static if(is(U S:S[])){
            foreach (ref el;a){
                el=cast(arrayBaseT!(U))getRandom();
            }
        } else {
            a=cast(U)getRandom();
        }
        return a;
    }
    /// initializes the variable with the result of mapping op on the random numbers (of type T)
    // unfortunately this (more efficent version) cannot use local delegates
    template randomizeOp2(alias op){
        U randomizeOp2(U)(ref U a){
            static if(is(U S:S[])){
                alias arrayBaseT!(U) TT;
                foreach (ref el;a){
                    static if(isComplex!(TT)) {
                        el=cast(TT)(op(getRandom())+1i*op(getRandom()));
                    } else static if (isImaginary!(TT)){
                        el=cast(TT)(1i*op(getRandom()));
                    } else {
                        el=cast(TT)op(getRandom());
                    }
                }
            } else {
                static if(isComplex!(U)) {
                    a=cast(U)(op(getRandom())+1i*op(getRandom()));
                } else static if (isImaginary!(U)){
                    el=cast(U)(1i*op(getRandom()));
                } else {
                    a=cast(U)op(getRandom());
                }
            }
            return a;
        }
    }
    /// initializes the variable with the result of mapping op on the random numbers (of type T)
    U randomizeOp(U,S)(S delegate(T) op,ref U a){
        static if(is(U S:S[])){
            alias arrayBaseT!(U) TT;
            foreach (ref el;a){
                static if(isComplex!(TT)) {
                    el=cast(TT)(op(getRandom())+1i*op(getRandom()));
                } else static if (isImaginary!(TT)){
                    el=cast(TT)(1i*op(getRandom()));
                } else {
                    el=cast(TT)op(getRandom());
                }
            }
        } else {
            static if(isComplex!(U)) {
                a=cast(U)(op(getRandom())+1i*op(getRandom()));
            } else static if (isImaginary!(U)){
                el=cast(U)(1i*op(getRandom()));
            } else {
                a=cast(U)op(getRandom());
            }
        }
        return a;
    }
    
}
