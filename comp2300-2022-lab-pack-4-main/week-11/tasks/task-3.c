int add_three(int a, int b, int c);
void square(int *a);

struct student {
  int uid;
  float score;
  char firstname[20];
  char lastname[20];
};

void cheat(struct student *stud);

int main(void)
{
  struct student std = {1234567, 77.6, "first", "last"};
  struct student *s = &std;

  cheat(s);
  
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

void cheat(struct student *stud)
{
  stud->score = 110;
  stud->lastname[0] = "X";
  return;
}