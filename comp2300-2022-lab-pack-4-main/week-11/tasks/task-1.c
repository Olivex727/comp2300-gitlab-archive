int add_three(int a, int b, int c);

int main(void)
{
  int x = add_three(1, 2, 3);
  return 0;
}

int add_three(int a, int b, int c)
{
  return a + b + c;
}