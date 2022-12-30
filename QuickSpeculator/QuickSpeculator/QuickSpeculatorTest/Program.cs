using System;

namespace QuickSpeculatorTest
{
    internal class Program
    {
        static void Main(string[] args)
        {
            var panelInfo =
                "11111 " +
                "-2222 " +
                "3333333 " +
                "4444444 " +
                "555555 " +
                "666666 " +
                "7777.77 " +
                "88.88 " +
                "-999999";
            QuickSpeculator.Show(panelInfo, 0, 99.99, 888888, -777777);

            Console.WriteLine("Hit [Enter] to exit...");
            Console.ReadLine();
            QuickSpeculator.Hide();
        }
    }
}
