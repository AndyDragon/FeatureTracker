using System;
using System.Windows.Input;

namespace Feature_Tracker
{
    internal class Command : ICommand
    {
        public event EventHandler CanExecuteChanged;

        private readonly Action execute;
        private readonly Func<bool> canExecute;

        public Command(Action execute, Func<bool> canExecute = null)
        {
            this.execute = execute ?? throw new ArgumentNullException("execute");
            this.canExecute = canExecute ?? (() => true);
        }

        public void OnCanExecuteChanged()
        {
            CanExecuteChanged?.Invoke(this, EventArgs.Empty);
        }

        public bool CanExecute(object o)
        {
            return canExecute();
        }

        public void Execute(object p)
        {
            if (!CanExecute(p))
            {
                return;
            }
            execute();
        }
    }
}
