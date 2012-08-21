// LZ77 compression / decompression algorithm
// this is the compression Microsoft used in Windows *.HLP and *.MRB files

// It is also used with Install Shield files.  These files are
// recognizable by the letters SZDD in the first 4 bytes.  The file
// names for files compressed in this way are usually the name of the
// file as it would be installed but with the last character replaced
// by '_'

// This program is a complete hack.  I am not responsible for the
// algorithm code in any way.  I stole the compression code from
// somebody else who didn't put a blame line in the file so I've
// forgotten who he was.  I just adapted it to run under linux from
// the command line.  (D. Risacher)


#define MSEXPAND 

#include <stdio.h>
#include <stdlib.h>

#define N 4096
#define F 16
#define THRESHOLD 3

#define dad (node+1)
#define lson (node+1+N)
#define rson (node+1+N+N)
#define root (node+1+N+N+N)
#define NIL -1

#define int16 short

char *buffer;
int16 *node;
int16 pos;

int filelength(FILE *f)
{
	int cur, size;
	cur = ftell(f);
	fseek(f, 0, SEEK_END);
	size = ftell(f);
	fseek(f, cur, SEEK_SET);
	return size;
}


#define min(x,y) (x>y?y:x)

int16 insert(int16 i,int16 run)
{
    int16 c,j,k,l,n,match;
    int16 *p;

    k=l=1;
    match=THRESHOLD-1;
    p=&root[(unsigned char)buffer[i]];
    lson[i]=rson[i]=NIL;
    while((j=*p)!=NIL)
    {
        for(n=min(k,l);n<run&&(c=(buffer[j+n]-buffer[i+n]))==0;n++) ;
        if(n>match)
        {
            match=n;
            pos=j;
        }
        if(c<0)
        {
            p=&lson[j];
            k=n;
        }
        else if(c>0)
        {
            p=&rson[j];
            l=n;
        }
        else
        {
            dad[j]=NIL;
            dad[lson[j]]=lson+i-node;
            dad[rson[j]]=rson+i-node;
            lson[i]=lson[j];
            rson[i]=rson[j];
            break;
        }
    }
    dad[i]=p-node;
    *p=i;
    return match;
}

void delete(int16 z)
{
    int16 j;

    if(dad[z]!=NIL)
    {
        if(rson[z]==NIL)
        {
            j=lson[z];
        }
        else if(lson[z]==NIL)
        {
            j=rson[z];
        }
        else
        {
            j=lson[z];
            if(rson[j]!=NIL)
            {
                do
                {
                    j=rson[j];
                }
                while(rson[j]!=NIL);
                node[dad[j]]=lson[j];
                dad[lson[j]]=dad[j];
                lson[j]=lson[z];
                dad[lson[z]]=lson+j-node;
            }
            rson[j]=rson[z];
            dad[rson[z]]=rson+j-node;
        }
        dad[j]=dad[z];
        node[dad[z]]=j;
        dad[z]=NIL;
    }
}

#pragma pack(push, 1)
struct header_struct { long magic, magic2; int16 magic3; long filesize; } __attribute__ ((packed));
#pragma pack(pop)

void compress(FILE *f,FILE *out)
{
    int16 ch,i,run,len,match,size,mask;
    char buf[17];

    buffer=malloc(N+F+(N+1+N+N+256)*sizeof(int16)); // 28.5 k !
    if(buffer)
    {
#ifdef MSEXPAND
        struct header_struct header;

        header.magic=0x44445A53L; // SZDD
        header.magic2=0x3327F088L;
        header.magic3=0x0041;
        header.filesize=filelength(f);
        fwrite(&header,sizeof(header),1,out);
#endif
        node=(int16 *)(buffer+N+F);
        for(i=0;i<256;i++) root[i]=NIL;
        for(i=NIL;i<N;i++) dad[i]=NIL;
        size=mask=1;
        buf[0]=0;
        i=N-F-F;
        for(len=0;len<F&&(ch=getc(f))!=-1;len++)
        {
            buffer[i+F]=ch;
            i=(i+1)&(N-1);
        }
        run=len;
        do
        {
            ch=getc(f);
            if(i>=N-F)
            {
                delete(i+F-N);
                buffer[i+F]=buffer[i+F-N]=ch;
            }
            else
            {
                delete(i+F);
                buffer[i+F]=ch;
            }
            match=insert(i,run);
            if(ch==-1)
            {
                run--;
                len--;
            }
            if(len++>=run)
            {
                if(match>=THRESHOLD)
                {
#ifdef MSEXPAND
                    buf[size++]=pos;
                    buf[size++]=((pos>>4)&0xF0)+(match-3);
#else
                    buf[0]|=mask;
                    *(int16 *)(buf+size)=((match-3)<<12)|((i-pos-1)&(N-1));
                    size+=2;
#endif
                    len-=match;
                }
                else
                {
#ifdef MSEXPAND
                    buf[0]|=mask;
#endif
                    buf[size++]=buffer[i];
                    len--;
                }
                if(!((mask+=mask)&0xFF))
                {
                    fwrite(buf,size,1,out);
                    size=mask=1;
                    buf[0]=0;
                }
            }
            i=(i+1)&(N-1);
        }
        while(len>0);
        if(size>1) fwrite(buf,size,1,out);
        free(buffer);
    }
}

void expand(FILE *f,FILE *out)
{
    int16 bits,ch,i,j,len,mask;
    char *buffer;

#ifdef MSEXPAND
    struct header_struct header;

    i=fread(&header,1,sizeof(header),f);
    if(i!=sizeof(header)||header.magic!=0x44445A53L||header.magic2!=0x3327F088L||header.magic3!=0x0041)
    {
        fwrite(&header,1,i,out);
        while((ch=getc(f))!=-1) putc(ch,out);
        return;
    } 
#endif
    buffer=malloc(N);
    if(buffer)
    {
        i=N-F;
        while(!feof(f))
        {
			bits=getc(f);
			//printf("%02X\n", bits);
            for(mask=0x01;mask&0xFF;mask<<=1)
            {
                if(!(bits&mask))
                {
                    j=getc(f);
                    if(j==-1) break;
                    len=getc(f);
                    j+=(len&0xF0)<<4;
                    len=(len&15)+3;
                    while(len--)
                    {
                        putc(buffer[i]=buffer[j],out);
                        j=(j+1)&(N-1);
                        i=(i+1)&(N-1);
                    }
                }
                else
                {
                    ch=getc(f);
                    putc(buffer[i]=ch,out);
                    i=(i+1)&(N-1);
                }
            }
        }
        free(buffer);
    }
}

int main (int argc, char**argv)
{
  FILE *fin, *fout;

  if (argc != 3) {
    fprintf(stderr, "%s: file-to-expand destination\n");
    fprintf(stderr, "WARNING: this program is a complete hack.\n");
    exit(1);
  }

  fin = fopen(argv[1],"rb");
  fout = fopen(argv[2],"wb");

  expand(fin, fout);
  
  fclose(fin);
  fclose(fout);
}