// BubbleSort
//# include <stdio.h>

int main(){

  unsigned int a[128];
  unsigned int array_size=128;  
  unsigned int i, j, temp;

  for (i = 0; i < (array_size - 1); ++i){
    for (j = 0; j < array_size - 1 - i; ++j ){
      if (a[j] > a[j+1]){
	temp = a[j+1];
	a[j+1] = a[j];
	a[j] = temp;
      }
    }
  }


  //  for (i =0;i<array_size;i++)
  // printf ("%d\n", a[i]);

}

