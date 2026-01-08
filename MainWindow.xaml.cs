using System;
using System.Collections.Generic;
using System.Linq;
using System.Windows;
using System.Windows.Automation;
using System.Windows.Automation.Peers;
using System.Windows.Automation.Provider;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Threading;
using Cribbage.Models;

namespace Cribbage
{
    public partial class MainWindow : Window
    {
        private CribbageGame game;
        private int currentCardIndex = 0;
        private DispatcherTimer? announcementTimer;
        private Queue<string> announcementQueue = new();
        private bool suppressIndividualAnnouncements = false;

        public MainWindow()
        {
            InitializeComponent();
            game = new CribbageGame();
            game.MessageAdded += OnGameMessage;
            game.StartNewGame();
            UpdateUI();
        }

        private void OnGameMessage(string message)
        {
            Dispatcher.Invoke(() =>
            {
                GameLogListBox.Items.Insert(0, message);

                if (!suppressIndividualAnnouncements)
                {
                    Announce(message);
                }
                else
                {
                    announcementQueue.Enqueue(message);
                }
            });
        }

        private void Announce(string message)
        {
            Console.WriteLine($"ANNOUNCE: {message}");
            
            // Update live region - clear first then set to ensure change detection
            LiveRegion.Text = string.Empty;
            LiveRegion.UpdateLayout();
            
            Dispatcher.InvokeAsync(() =>
            {
                LiveRegion.Text = message;
                
                // Force automation peer to notify
                var peer = UIElementAutomationPeer.CreatePeerForElement(LiveRegion);
                if (peer != null)
                {
                    peer.RaiseAutomationEvent(AutomationEvents.LiveRegionChanged);
                }
            }, DispatcherPriority.Background);
        }

        private void BatchAnnounce(int delayMs)
        {
            announcementTimer?.Stop();
            announcementTimer = new DispatcherTimer
            {
                Interval = TimeSpan.FromMilliseconds(delayMs)
            };
            announcementTimer.Tick += (s, e) =>
            {
                if (announcementQueue.Count > 0)
                {
                    var message = announcementQueue.Dequeue();
                    Announce(message);

                    if (announcementQueue.Count > 0)
                    {
                        announcementTimer?.Start();
                    }
                    else
                    {
                        announcementTimer?.Stop();
                    }
                }
            };
            announcementTimer.Start();
        }

        private void UpdateUI()
        {
            // Update scores
            PlayerScoreLabel.Text = $"PLAYER: {game.Player.Score}";
            PlayerScoreBar.Value = game.Player.Score;
            ComputerScoreLabel.Text = $"COMPUTER: {game.Computer.Score}";
            ComputerScoreBar.Value = game.Computer.Score;

            // Update played cards label with count
            PlayedGroupBox.Header = $"Played Cards (Count: {game.CurrentCount})";

            // Update dealer info in crib label
            if (game.Dealer != null)
            {
                ((GroupBox)CribPanel.Parent).Header = $"The Crib ({game.Dealer.Name}'s)";
            }

            // Render all card areas
            RenderPlayerHand();
            RenderComputerHand();
            RenderCrib();
            RenderPlayedCards();

            // Update button states
            CutButton.IsEnabled = game.State == GameState.CutForDeal;
            GoButton.IsEnabled = game.State == GameState.Play && game.CurrentTurn == game.Player;
            
            bool canContinue = game.State == GameState.Pause31 || 
                             game.State == GameState.PauseGo ||
                             game.State == GameState.PauseBeforeCount ||
                             game.State == GameState.RoundOver ||
                             (game.State == GameState.Discard && game.SelectedForDiscard.Count == 2);
            ContinueButton.IsEnabled = canContinue;
        }

        private void RenderPlayerHand()
        {
            PlayerHandPanel.Items.Clear();
            game.Player.SortHand();

            for (int i = 0; i < game.Player.Hand.Count; i++)
            {
                var card = game.Player.Hand[i];
                var button = CreateCardButton(card, i, game.Player.Hand.Count, true);
                
                // Handle selection for discard phase
                if (game.State == GameState.Discard && game.SelectedForDiscard.Contains(i))
                {
                    button.Style = (Style)FindResource("SelectedCardButton");
                }

                // Handle played cards
                if (game.Player.PlayedCards.Contains(card))
                {
                    button.IsEnabled = false;
                }

                int index = i; // Capture for lambda
                button.Click += (s, e) => HandleCardClick(index);
                
                // Make buttons not tabbable - ListBox handles navigation
                button.IsTabStop = false;
                button.Focusable = false;
                
                PlayerHandPanel.Items.Add(button);
            }

            // Ensure current index is valid
            if (currentCardIndex >= game.Player.Hand.Count)
            {
                currentCardIndex = Math.Max(0, game.Player.Hand.Count - 1);
            }
            
            // Set focus to current card
            if (game.Player.Hand.Count > 0)
            {
                PlayerHandPanel.SelectedIndex = currentCardIndex;
            }
        }

        private void RenderComputerHand()
        {
            ComputerHandPanel.Children.Clear();
            for (int i = 0; i < game.Computer.Hand.Count; i++)
            {
                var button = CreateCardButton(null, i, game.Computer.Hand.Count, false);
                button.IsEnabled = false;
                ComputerHandPanel.Children.Add(button);
            }
        }

        private void RenderCrib()
        {
            CribPanel.Children.Clear();
            for (int i = 0; i < game.Crib.Count; i++)
            {
                var button = CreateCardButton(null, i, game.Crib.Count, false);
                button.IsEnabled = false;
                CribPanel.Children.Add(button);
            }
        }

        private void RenderPlayedCards()
        {
            PlayedPanel.Children.Clear();
            foreach (var (card, player) in game.PlayedPile)
            {
                var button = CreateCardButton(card, 0, game.PlayedPile.Count, true);
                button.IsEnabled = false;
                PlayedPanel.Children.Add(button);
            }
        }

        private Button CreateCardButton(Card? card, int index, int total, bool isPlayerCard)
        {
            var button = new Button
            {
                Style = (Style)FindResource("CardButton")
            };

            if (card == null || !isPlayerCard)
            {
                button.Content = "[?]";
                button.SetValue(AutomationProperties.NameProperty, "Face down card");
            }
            else
            {
                // Create a TextBlock for visual content
                var textBlock = new TextBlock
                {
                    Text = $"{card.Rank}{card.Suit}",
                    FontSize = 20,
                    FontWeight = FontWeights.Bold,
                    HorizontalAlignment = HorizontalAlignment.Center,
                    VerticalAlignment = VerticalAlignment.Center
                };
                
                // Make the TextBlock invisible to screen readers by setting it as content view only
                AutomationProperties.SetIsOffscreenBehavior(textBlock, IsOffscreenBehavior.FromClip);
                AutomationProperties.SetLabeledBy(textBlock, button);
                
                button.Content = textBlock;
                
                var accessibleName = $"{card.Name}, card {index + 1} of {total}";
                button.SetValue(AutomationProperties.NameProperty, accessibleName);
                
                // Color red cards
                if (card.IsRed)
                {
                    textBlock.Foreground = Brushes.Red;
                }
            }

            return button;
        }

        private void HandleCardClick(int index)
        {
            if (index >= game.Player.Hand.Count) return;

            var card = game.Player.Hand[index];

            if (game.State == GameState.Discard)
            {
                if (game.SelectedForDiscard.Contains(index))
                {
                    game.SelectedForDiscard.Remove(index);
                    Announce($"{card.Name} unselected. {game.SelectedForDiscard.Count} of 2 selected.");
                }
                else if (game.SelectedForDiscard.Count < 2)
                {
                    game.SelectedForDiscard.Add(index);
                    Announce($"{card.Name} selected. {game.SelectedForDiscard.Count} of 2 selected.");
                }
                else
                {
                    Announce("Already have 2 cards selected. Unselect a card first.");
                }
                UpdateUI();
            }
            else if (game.State == GameState.Play && game.CurrentTurn == game.Player)
            {
                if (game.CanPlayCard(game.Player, card))
                {
                    game.PlayCard(game.Player, card);
                    
                    // Adjust current card index
                    if (index <= currentCardIndex && currentCardIndex > 0)
                    {
                        currentCardIndex--;
                    }
                    currentCardIndex = Math.Min(currentCardIndex, game.Player.Hand.Count - 1);
                    
                    UpdateUI();
                    
                    // Computer plays if it's their turn
                    if (game.State == GameState.Play && game.CurrentTurn == game.Computer)
                    {
                        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(1000) };
                        timer.Tick += (s, e) =>
                        {
                            timer.Stop();
                            ComputerPlay();
                        };
                        timer.Start();
                    }
                }
                else
                {
                    Announce("Cannot play that card - would exceed 31.");
                }
            }
        }

        private void ComputerPlay()
        {
            if (game.State != GameState.Play || game.CurrentTurn != game.Computer) return;

            // Simple AI: play first valid card
            var validCard = game.Computer.Hand.FirstOrDefault(c => 
                !game.Computer.PlayedCards.Contains(c) && 
                game.CurrentCount + c.Value <= 31);

            if (validCard != null)
            {
                game.PlayCard(game.Computer, validCard);
                UpdateUI();

                // Continue if still computer's turn
                if (game.State == GameState.Play && game.CurrentTurn == game.Computer)
                {
                    var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(1000) };
                    timer.Tick += (s, e) =>
                    {
                        timer.Stop();
                        ComputerPlay();
                    };
                    timer.Start();
                }
            }
            else
            {
                game.SayGo();
                UpdateUI();
            }
        }

        private void PlayerHandPanel_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (PlayerHandPanel.SelectedIndex >= 0 && PlayerHandPanel.SelectedIndex < game.Player.Hand.Count)
            {
                currentCardIndex = PlayerHandPanel.SelectedIndex;
                var card = game.Player.Hand[currentCardIndex];
                var selectionStatus = game.SelectedForDiscard.Contains(currentCardIndex) ? "selected for discard" : "not selected";
                Announce($"{card.Name}, card {currentCardIndex + 1} of {game.Player.Hand.Count}, {selectionStatus}");
            }
        }

        // Keyboard Navigation
        private void PlayerHandPanel_KeyDown(object sender, KeyEventArgs e)
        {
            var cardCount = PlayerHandPanel.Items.Count;
            if (cardCount == 0) return;

            switch (e.Key)
            {
                case Key.Left:
                    if (currentCardIndex > 0)
                    {
                        currentCardIndex--;
                        PlayerHandPanel.SelectedIndex = currentCardIndex;
                        e.Handled = true;
                    }
                    break;

                case Key.Right:
                    if (currentCardIndex < cardCount - 1)
                    {
                        currentCardIndex++;
                        PlayerHandPanel.SelectedIndex = currentCardIndex;
                        e.Handled = true;
                    }
                    break;

                case Key.Home:
                    currentCardIndex = 0;
                    PlayerHandPanel.SelectedIndex = currentCardIndex;
                    e.Handled = true;
                    break;

                case Key.End:
                    currentCardIndex = cardCount - 1;
                    PlayerHandPanel.SelectedIndex = currentCardIndex;
                    e.Handled = true;
                    break;

                case Key.Space:
                case Key.Enter:
                    HandleCardClick(currentCardIndex);
                    e.Handled = true;
                    break;
            }
        }

        private void Window_KeyDown(object sender, KeyEventArgs e)
        {
            // Global keyboard shortcuts
            if (e.Key == Key.N && Keyboard.Modifiers == ModifierKeys.Control)
            {
                NewGameButton_Click(sender, e);
                e.Handled = true;
            }
        }

        // Button Event Handlers
        private void CutButton_Click(object sender, RoutedEventArgs e)
        {
            suppressIndividualAnnouncements = true;
            int messagesBefore = GameLogListBox.Items.Count;

            game.CutForDeal();
            UpdateUI();

            suppressIndividualAnnouncements = false;

            // Batch announce
            int messagesAfter = GameLogListBox.Items.Count;
            int newMessages = messagesAfter - messagesBefore;
            if (newMessages > 0)
            {
                BatchAnnounce(150);
            }

            if (game.State == GameState.Discard)
            {
                var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(100) };
                timer.Tick += (s, ev) =>
                {
                    timer.Stop();
                    PlayerHandPanel.Focus();
                };
                timer.Start();
            }
        }

        private void GoButton_Click(object sender, RoutedEventArgs e)
        {
            var stateBefore = game.State;
            game.SayGo();
            UpdateUI();

            // Only auto-trigger computer if state is still Play (meaning other player continues)
            // Don't trigger if state changed to PauseGo
            if (game.State == GameState.Play && stateBefore == GameState.Play && game.CurrentTurn == game.Computer)
            {
                var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(1000) };
                timer.Tick += (s, ev) =>
                {
                    timer.Stop();
                    ComputerPlay();
                };
                timer.Start();
            }
        }

        private void ContinueButton_Click(object sender, RoutedEventArgs e)
        {
            if (game.State == GameState.Discard && game.SelectedForDiscard.Count == 2)
            {
                suppressIndividualAnnouncements = true;
                int messagesBefore = GameLogListBox.Items.Count;

                game.DiscardCards();
                UpdateUI();

                suppressIndividualAnnouncements = false;

                int messagesAfter = GameLogListBox.Items.Count;
                int newMessages = messagesAfter - messagesBefore;
                if (newMessages > 0)
                {
                    BatchAnnounce(150);
                }

                if (game.State == GameState.Play && game.CurrentTurn == game.Computer)
                {
                    var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(1500) };
                    timer.Tick += (s, ev) =>
                    {
                        timer.Stop();
                        ComputerPlay();
                    };
                    timer.Start();
                }
            }
            else if (game.State == GameState.Pause31 || game.State == GameState.PauseGo)
            {
                // Continuing from a pause - resume play but give user control
                // The computer should NOT auto-play here because the user just pressed Continue
                // to acknowledge the 31 or Go. If it's computer's turn, it will play when
                // the user takes their next action (or we can add a small delay)
                var previousState = game.State;
                game.ContinueAfterPause();
                UpdateUI();
                
                // After resuming from pause, if it's computer's turn, give a delay for user to see the state
                if (game.State == GameState.Play && game.CurrentTurn == game.Computer)
                {
                    var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(1500) };
                    timer.Tick += (s, ev) =>
                    {
                        timer.Stop();
                        ComputerPlay();
                    };
                    timer.Start();
                }
            }
            else
            {
                // Other continue cases (PauseBeforeCount, RoundOver)
                game.ContinueAfterPause();
                UpdateUI();
            }
        }

        private void NewGameButton_Click(object sender, RoutedEventArgs e)
        {
            game.StartNewGame();
            currentCardIndex = 0;
            UpdateUI();
        }
    }
}
