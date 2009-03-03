module tango.stdc.constants.autoConf.sysctl;
version(autoConf){
    pragma(msg,"non generated constants you can try to generate new ones running tango/lib/constants/dppAll.sh or dppAll2.sh and manual editing and then use -version=autoConf");
    pragma(msg,"please contact the tango team and help porting tango to your platform");
    static assert(0,"non generated constants in "~__FILE__);
}