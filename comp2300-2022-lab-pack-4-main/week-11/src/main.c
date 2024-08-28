int main(void)
{
  volatile int *GPIO_P0_DIR = (int*) 0x50000514;
  *GPIO_P0_DIR = *GPIO_P0_DIR | (1 << 21) | (1 << 28);

  volatile int *GPIO_P0_OUT = (int*) 0x50000504;
  *GPIO_P0_OUT = *GPIO_P0_OUT | (1 << 21);

  return 0;
}