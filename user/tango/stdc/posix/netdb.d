/+
+ stdc netdb.h header file.
+ more function are defined, see http://www.opengroup.org/onlinepubs/009695399/basedefs/netdb.h.html
+ if needed add them, at the moment only the basic ones are defined
+
+ license: tango/apache
+ author: fawzi
+/
module tango.stdc.posix.netdb;
import tango.stdc.posix.sys.socket: socklen_t;

extern(C):

void endhostent();

hostent *gethostbyaddr(void *addr, socklen_t len, int type);
hostent *gethostbyname(char *name);
hostent *gethostbyname2(char *name, int af);

hostent * gethostent();

//extern int h_errno;
//void herror(char *string);
//char *hstrerror(int err);

void sethostent(int stayopen);

struct hostent
{
    char* h_name;
    char** h_aliases;
    int h_addrtype;
    int h_length;
    char** h_addr_list;

    char* h_addr()
    {
            return h_addr_list[0];
    }
}
