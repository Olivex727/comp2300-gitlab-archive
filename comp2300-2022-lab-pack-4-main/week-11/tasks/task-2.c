int add_three(int a, int b, int c);
void square(int *a);

int main(void)
{
  int x = add_three(1, 2, 3);
  int *p = &x;
  square(p);
  return 0;
}

int add_three(int a, int b, int c)
{
  return a + b + c;
}

void square(int *a)
{
  *a = *a * *a;
  return;
}