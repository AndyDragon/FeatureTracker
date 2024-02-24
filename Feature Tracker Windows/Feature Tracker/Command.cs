using System;
using System.Windows.Input;

namespace FeatureTracker
{
    internal class Command(Action execute, Func<bool>? canExecute = null) : ICommand
    {
        public event EventHandler? CanExecuteChanged;

        private readonly Action execute = execute ?? throw new ArgumentNullException("execute");
        private readonly Func<bool> canExecute = canExecute ?? (() => true);

        public void OnCanExecuteChanged()
        {
            CanExecuteChanged?.Invoke(this, EventArgs.Empty);
        }

        public bool CanExecute(object? sender) => canExecute();

        public void Execute(object? sender)
        {
            if (!CanExecute(sender))
            {
                return;
            }
            execute();
        }
    }

    internal class CommandWithParameter(Action<object?> execute, Func<object?, bool>? canExecute = null) : ICommand
    {
        public event EventHandler? CanExecuteChanged;

        private readonly Action<object?> execute = execute ?? throw new ArgumentNullException("execute");
        private readonly Func<object?, bool> canExecute = canExecute ?? ((parameter) => true);

        public void OnCanExecuteChanged()
        {
            CanExecuteChanged?.Invoke(this, EventArgs.Empty);
        }

        public bool CanExecute(object? sender) => canExecute(sender);

        public void Execute(object? sender)
        {
            if (!CanExecute(sender))
            {
                return;
            }
            execute(sender);
        }
    }
}
