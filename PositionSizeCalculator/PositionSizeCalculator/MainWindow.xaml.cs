using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace PositionSizeCalculator
{
    public partial class MainWindow : Window
    {

        public MainWindow()
        {
            InitializeComponent();


        }

        private void CurrencyPairComboBox_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (CurrencyPairComboBox.SelectedItem is ComboBoxItem selectedItem)
            {
                string pair = selectedItem.Content.ToString();
                ResultText.Text = $"Your pair: {pair}";
                // Здесь можно вызвать метод расчёта размера позиции
            }
        }
        private void CalculateButton_Click(object sender, RoutedEventArgs e)
        {
            // Получаем введённые данные
            string accountSizeText = AccountSizeTextBox.Text;
            string stopLossText = StopLossTextBox.Text;
            string riskRatioText = RiskRatioTextBox.Text;


            if (double.TryParse(accountSizeText, out double accountSize)
                && double.TryParse(stopLossText, out double stopLossInTicks)
                && double.TryParse(riskRatioText, out double riskRatio)
                && stopLossInTicks > 0)
            {

                double riskAmount = accountSize * (riskRatio / 100); //Risk in $

                double positionSize = riskAmount / stopLossInTicks;

                ResultText.Text = $"Lots(position size): {positionSize}";
            }
            else
            {
                ResultText.Text = "Incorrect";
            }
        }


    }
}
