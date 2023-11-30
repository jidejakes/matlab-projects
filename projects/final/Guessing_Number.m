%GAME->GUESS NUMBER

%1. THINK OF A NUMBER BETWEEN 1 TO 63.
%2. CPU SHOWS SOME TABLES WHERE U NEED TO TELL WHEATHER UR NUMBER IS
%   THERE OR NOT.
%3. FINALLY CPU IDENTIFIES UR NUMBER.

 %-----------------------------------------------------------------------
 %initialisation
 
 clear all
 clc
 A=1;B=1;C=1;D=1;E=1;F=1;
 Box=zeros(7,36);
 sum=0;
 axis off
 text(0,0.5,'THINK A NUMBER BETWEEN 1 n 63:','color','r','fontsize',20); 
 pause(3);
 %-----------------------------------------------------------------------
 %logic
 
 for ii=1:63   
     M=ii;
     for jj=6:-1:1
         array(jj)=mod(M,2);
         M=floor(M/2);
         if(array(jj)==1)
              switch jj              
                case 1, Box(6,A)=ii; A=A+1;   
                case 2, Box(5,B)=ii; B=B+1;   
                case 3, Box(4,C)=ii; C=C+1;  
                case 4, Box(3,D)=ii; D=D+1;   
                case 5, Box(2,E)=ii; E=E+1;   
                case 6, Box(1,F)=ii; F=F+1;                                        
              end
          end
      end     
  end
%-----------------------------------------------------------------------
 %display of board

for kk=1:6
clf
for ii=1:6    
    for jj=1:6
        axis off
        rectangle('Position', [0+ii 0+jj 1 1],'linewidth',5);
        X=[0+ii 1+ii 1+ii 0+ii];
        Y=[0+jj 0+jj 1+jj 1+jj];
        hold on
        ll=(6*ii+jj-6);
        text(ii+0.3,jj+0.5,sprintf('%d ',Box(kk,ll)),'color','w','fontsize',20);
        axis([0 7 -1 7]);
    end   
end
%-----------------------------------------------------------------------
%plotting buttons

 title('IS UR NUMBER PRESENT IN THIS TABLE???');
 Xcir=3+0.5*cos(0:1/50:2*pi);
 Ycir=-0.5+0.5*sin(0:1/50:2*pi);
 plot(Xcir,Ycir);
 fill(Xcir,Ycir,'w');
 Xcir=5+0.5*cos(0:1/50:2*pi);
 Ycir=-0.5+0.5*sin(0:1/50:2*pi);
 plot(Xcir,Ycir);
 fill(Xcir,Ycir,'k');
 text(2.7,-0.5,sprintf('%s','Yes'),'fontsize',15,'color','k');
 text(4.85,-0.5,sprintf('%s','No'),'fontsize',15,'color','w');
 %-----------------------------------------------------------------------
 %interaction
    
      [Xnew Ynew Button] = ginput(1);

      if Button==1          
          if (Xnew>2.5 & Xnew<3.5)
              sum=sum+Box(kk,1);          
          end         
      end  
      
      if Button==2  break;  end
 end
 %-----------------------------------------------------------------------
 %answer
 
 clf
 axis off
 text(0,0.5,sprintf('NUMBER IN YOUR MIND IS %d',sum),'color','b','fontsize',20);
 %-----------------------------------------------------------------------