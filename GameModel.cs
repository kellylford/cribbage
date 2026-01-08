using System;
using System.Collections.Generic;
using System.Linq;

namespace Cribbage.Models
{
    public class Card
    {
        public string Rank { get; set; }
        public string Suit { get; set; }

        private static readonly Dictionary<string, string> RankNames = new()
        {
            {"A", "Ace"}, {"2", "Two"}, {"3", "Three"}, {"4", "Four"}, {"5", "Five"},
            {"6", "Six"}, {"7", "Seven"}, {"8", "Eight"}, {"9", "Nine"}, {"10", "Ten"},
            {"J", "Jack"}, {"Q", "Queen"}, {"K", "King"}
        };

        private static readonly Dictionary<string, string> SuitNames = new()
        {
            {"♥", "Hearts"}, {"♦", "Diamonds"}, {"♣", "Clubs"}, {"♠", "Spades"}
        };

        public Card(string rank, string suit)
        {
            Rank = rank;
            Suit = suit;
        }

        public int Value
        {
            get
            {
                var ranks = new[] { "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K" };
                int rankValue = Array.IndexOf(ranks, Rank) + 1;
                return Math.Min(rankValue, 10);
            }
        }

        public int RankValue
        {
            get
            {
                var ranks = new[] { "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K" };
                return Array.IndexOf(ranks, Rank) + 1;
            }
        }

        public string Name => $"{RankNames[Rank]} of {SuitNames[Suit]}";
        
        public bool IsRed => Suit == "♥" || Suit == "♦";

        public override string ToString() => Name;
    }

    public class Deck
    {
        private List<Card> cards;
        private Random random;

        public Deck()
        {
            random = new Random();
            cards = new List<Card>();
            var suits = new[] { "♥", "♦", "♣", "♠" };
            var ranks = new[] { "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K" };

            foreach (var suit in suits)
            {
                foreach (var rank in ranks)
                {
                    cards.Add(new Card(rank, suit));
                }
            }

            Shuffle();
        }

        public void Shuffle()
        {
            cards = cards.OrderBy(x => random.Next()).ToList();
        }

        public Card? Deal()
        {
            if (cards.Count == 0) return null;
            var card = cards[^1];
            cards.RemoveAt(cards.Count - 1);
            return card;
        }
    }

    public class Player
    {
        public string Name { get; set; }
        public List<Card> Hand { get; set; }
        public List<Card> PlayedCards { get; set; }
        public int Score { get; set; }
        public bool IsComputer { get; set; }

        public Player(string name, bool isComputer = false)
        {
            Name = name;
            Hand = new List<Card>();
            PlayedCards = new List<Card>();
            Score = 0;
            IsComputer = isComputer;
        }

        public void AddCard(Card card)
        {
            Hand.Add(card);
        }

        public bool RemoveCard(Card card)
        {
            return Hand.Remove(card);
        }

        public bool PlayCard(Card card)
        {
            if (RemoveCard(card))
            {
                PlayedCards.Add(card);
                return true;
            }
            return false;
        }

        public void ClearPlayedCards()
        {
            PlayedCards.Clear();
        }

        public void ResetHand()
        {
            Hand.Clear();
            PlayedCards.Clear();
        }

        public void SortHand()
        {
            Hand = Hand.OrderBy(c => c.RankValue).ToList();
        }
    }

    public enum GameState
    {
        CutForDeal,
        Discard,
        Play,
        Pause31,
        PauseGo,
        PauseBeforeCount,
        RoundOver,
        GameOver
    }

    public class CribbageGame
    {
        public Player Player { get; private set; }
        public Player Computer { get; private set; }
        public List<Card> Crib { get; private set; }
        public Card? CutCard { get; private set; }
        public Player? Dealer { get; private set; }
        public Player? CurrentTurn { get; private set; }
        public List<(Card Card, Player Player)> PlayedPile { get; private set; }
        public int CurrentCount { get; private set; }
        public GameState State { get; private set; }
        public HashSet<int> SelectedForDiscard { get; private set; }

        public event Action<string>? MessageAdded;

        private Deck? deck;
        private Random random;

        public CribbageGame()
        {
            random = new Random();
            Player = new Player("Player", false);
            Computer = new Player("Computer", true);
            Crib = new List<Card>();
            PlayedPile = new List<(Card, Player)>();
            SelectedForDiscard = new HashSet<int>();
            State = GameState.CutForDeal;
        }

        public void StartNewGame()
        {
            Player.Score = 0;
            Computer.Score = 0;
            State = GameState.CutForDeal;
            AddMessage("New game started. Click Cut for Deal to begin.");
        }

        public void CutForDeal()
        {
            if (State != GameState.CutForDeal) return;

            var deck1 = new Deck();
            var deck2 = new Deck();

            var playerCut = deck1.Deal();
            var computerCut = deck2.Deal();

            if (playerCut == null || computerCut == null) return;

            AddMessage($"You cut: {playerCut.Name}");
            AddMessage($"Computer cut: {computerCut.Name}");

            if (playerCut.RankValue < computerCut.RankValue)
            {
                Dealer = Player;
                AddMessage("You deal first (lower card).");
            }
            else if (computerCut.RankValue < playerCut.RankValue)
            {
                Dealer = Computer;
                AddMessage("Computer deals first (lower card).");
            }
            else
            {
                AddMessage("Tie! Cut again.");
                return;
            }

            StartNewRound();
        }

        private void StartNewRound()
        {
            Player.ResetHand();
            Computer.ResetHand();
            Crib.Clear();
            PlayedPile.Clear();
            CurrentCount = 0;
            CutCard = null;
            SelectedForDiscard.Clear();

            deck = new Deck();

            // Deal 6 cards to each player
            for (int i = 0; i < 6; i++)
            {
                Player.AddCard(deck.Deal()!);
                Computer.AddCard(deck.Deal()!);
            }

            Player.SortHand();
            Computer.SortHand();

            State = GameState.Discard;
            AddMessage($"{Dealer?.Name} is the dealer. Select 2 cards to discard to the crib.");
        }

        public void DiscardCards()
        {
            if (State != GameState.Discard || SelectedForDiscard.Count != 2) return;

            // Player discards
            var playerDiscards = SelectedForDiscard.OrderByDescending(i => i).ToList();
            foreach (var index in playerDiscards)
            {
                if (index < Player.Hand.Count)
                {
                    var card = Player.Hand[index];
                    Crib.Add(card);
                    Player.Hand.RemoveAt(index);
                }
            }

            SelectedForDiscard.Clear();

            // Computer discards (simple AI - discard lowest value cards)
            var computerDiscards = Computer.Hand.OrderBy(c => c.Value).Take(2).ToList();
            foreach (var card in computerDiscards)
            {
                Crib.Add(card);
                Computer.RemoveCard(card);
            }

            AddMessage("Cards discarded to crib.");

            // Cut the deck
            CutCard = deck?.Deal();
            if (CutCard != null)
            {
                AddMessage($"Cut card: {CutCard.Name}");

                // Check for "his heels" (Jack cut by dealer)
                if (CutCard.Rank == "J")
                {
                    if (Dealer != null)
                    {
                        Dealer.Score += 2;
                        AddMessage($"{Dealer.Name} scores 2 for his heels!");
                    }
                }
            }

            // Start play - non-dealer goes first
            CurrentTurn = Dealer == Player ? Computer : Player;
            State = GameState.Play;
            AddMessage($"{CurrentTurn.Name}'s turn to play.");
        }

        public bool CanPlayCard(Player player, Card card)
        {
            if (State != GameState.Play || CurrentTurn != player) return false;
            if (player.PlayedCards.Contains(card)) return false;
            return CurrentCount + card.Value <= 31;
        }

        public void PlayCard(Player player, Card card)
        {
            if (!CanPlayCard(player, card)) return;

            player.PlayCard(card);
            PlayedPile.Add((card, player));
            CurrentCount += card.Value;

            AddMessage($"{player.Name} plays {card.Name}. Count: {CurrentCount}");

            // Check for scoring
            CheckPlayScoring(player);

            // Check for 31
            if (CurrentCount == 31)
            {
                player.Score += 2;
                AddMessage($"{player.Name} scores 2 for 31!");
                ResetCount();
                
                // Check if play is complete
                if (Player.Hand.Count == 0 && Computer.Hand.Count == 0)
                {
                    AddMessage("Play complete. Counting hands...");
                    State = GameState.PauseBeforeCount;
                }
                else
                {
                    // Player who got 31 continues (non-dealer leads after 31)
                    CurrentTurn = Dealer == Player ? Computer : Player;
                    State = GameState.Pause31;
                }
                return;
            }

            // Switch turns
            CurrentTurn = CurrentTurn == Player ? Computer : Player;

            // Check if next player can play
            if (!CanPlayerPlay(CurrentTurn))
            {
                AddMessage($"{CurrentTurn.Name} cannot play.");
                CurrentTurn = player;
                
                if (!CanPlayerPlay(CurrentTurn))
                {
                    AddMessage("Go!");
                    // Last player to play gets the Go point
                    player.Score += 1;
                    AddMessage($"{player.Name} scores 1 for Go!");
                    ResetCount();
                    
                    // Check if play is complete
                    if (Player.Hand.Count == 0 && Computer.Hand.Count == 0)
                    {
                        AddMessage("Play complete. Counting hands...");
                        State = GameState.PauseBeforeCount;
                    }
                    else
                    {
                        // Player who got the Go continues
                        CurrentTurn = player;
                        State = GameState.PauseGo;
                    }
                    return; // Don't continue - we're in a pause state
                }
                return; // Player got to continue after opponent couldn't play
            }
            else
            {
                // Check if play is complete (both hands empty)
                if (Player.Hand.Count == 0 && Computer.Hand.Count == 0)
                {
                    AddMessage("Play complete. Counting hands...");
                    State = GameState.PauseBeforeCount;
                }
            }
        }

        private bool CanPlayerPlay(Player player)
        {
            return player.Hand.Any(card => !player.PlayedCards.Contains(card) && 
                                           CurrentCount + card.Value <= 31);
        }

        private void CheckPlayScoring(Player player)
        {
            // 15 - two points
            if (CurrentCount == 15)
            {
                player.Score += 2;
                AddMessage($"{player.Name} scores 2 for fifteen!");
            }

            // Pairs, trips, quads
            if (PlayedPile.Count >= 2)
            {
                var lastCard = PlayedPile[^1].Card;
                var matchCount = 1;

                for (int i = PlayedPile.Count - 2; i >= 0 && PlayedPile[i].Card.Rank == lastCard.Rank; i--)
                {
                    matchCount++;
                }

                if (matchCount >= 2)
                {
                    int points = matchCount == 2 ? 2 : matchCount == 3 ? 6 : 12;
                    player.Score += points;
                    string scoreName = matchCount == 2 ? "pair" : matchCount == 3 ? "three of a kind" : "four of a kind";
                    AddMessage($"{player.Name} scores {points} for {scoreName}!");
                }
            }

            // Runs - check for sequences of 3 or more
            if (PlayedPile.Count >= 3)
            {
                for (int len = PlayedPile.Count; len >= 3; len--)
                {
                    var recentCards = PlayedPile.Skip(PlayedPile.Count - len)
                                                .Select(p => p.Card.RankValue)
                                                .OrderBy(r => r)
                                                .ToList();
                    
                    bool isRun = true;
                    for (int i = 1; i < recentCards.Count; i++)
                    {
                        if (recentCards[i] != recentCards[i - 1] + 1)
                        {
                            isRun = false;
                            break;
                        }
                    }

                    if (isRun)
                    {
                        player.Score += len;
                        AddMessage($"{player.Name} scores {len} for a run of {len}!");
                        break;
                    }
                }
            }
        }

        public void SayGo()
        {
            if (State != GameState.Play || CurrentTurn == null) return;

            var otherPlayer = CurrentTurn == Player ? Computer : Player;
            
            if (CanPlayerPlay(otherPlayer))
            {
                AddMessage($"{otherPlayer.Name} continues playing.");
                CurrentTurn = otherPlayer;
            }
            else
            {
                // The player who said Go (CurrentTurn) gets the point
                AddMessage($"{CurrentTurn.Name} gets 1 for Go!");
                CurrentTurn.Score += 1;
                ResetCount();
                
                // Check if play is complete
                if (Player.Hand.Count == 0 && Computer.Hand.Count == 0)
                {
                    AddMessage("Play complete. Counting hands...");
                    State = GameState.PauseBeforeCount;
                }
                else
                {
                    // Player who got the Go leads next
                    State = GameState.PauseGo;
                }
            }
        }

        private void ResetCount()
        {
            CurrentCount = 0;
            PlayedPile.Clear();
            Player.ClearPlayedCards();
            Computer.ClearPlayedCards();
        }

        public void ContinueAfterPause()
        {
            if (State == GameState.Pause31 || State == GameState.PauseGo)
            {
                if (Player.Hand.Count == 0 && Computer.Hand.Count == 0)
                {
                    AddMessage("Counting hands...");
                    State = GameState.PauseBeforeCount;
                }
                else
                {
                    // CurrentTurn was already set to whoever should lead (non-dealer after 31, or whoever got the Go)
                    State = GameState.Play;
                    AddMessage($"{CurrentTurn?.Name}'s turn.");
                }
            }
            else if (State == GameState.PauseBeforeCount)
            {
                CountHands();
            }
            else if (State == GameState.RoundOver)
            {
                if (Player.Score >= 121 || Computer.Score >= 121)
                {
                    State = GameState.GameOver;
                    string winner = Player.Score >= 121 ? "Player" : "Computer";
                    AddMessage($"Game Over! {winner} wins!");
                }
                else
                {
                    Dealer = Dealer == Player ? Computer : Player;
                    StartNewRound();
                }
            }
        }

        private void CountHands()
        {
            // Count non-dealer hand first
            var nonDealer = Dealer == Player ? Computer : Player;
            CountHand(nonDealer, nonDealer.Hand, false);

            // Check for win
            if (nonDealer.Score >= 121)
            {
                State = GameState.GameOver;
                AddMessage($"{nonDealer.Name} wins!");
                return;
            }

            // Count dealer hand
            if (Dealer != null)
            {
                CountHand(Dealer, Dealer.Hand, false);
            }

            // Check for win
            if (Dealer?.Score >= 121)
            {
                State = GameState.GameOver;
                AddMessage($"{Dealer.Name} wins!");
                return;
            }

            // Count crib (belongs to dealer)
            if (Dealer != null)
            {
                CountHand(Dealer, Crib, true);
            }

            // Check for win
            if (Dealer?.Score >= 121)
            {
                State = GameState.GameOver;
                AddMessage($"{Dealer.Name} wins!");
                return;
            }

            State = GameState.RoundOver;
            AddMessage("Round complete. Click Continue for next round.");
        }

        private void CountHand(Player player, List<Card> hand, bool isCrib)
        {
            int points = 0;
            string handType = isCrib ? "crib" : "hand";

            // Fifteens
            int fifteens = CountFifteens(hand);
            if (fifteens > 0)
            {
                points += fifteens * 2;
                AddMessage($"{player.Name}'s {handType}: {fifteens * 2} points for {fifteens} fifteens");
            }

            // Pairs
            int pairs = CountPairs(hand);
            if (pairs > 0)
            {
                points += pairs * 2;
                AddMessage($"{player.Name}'s {handType}: {pairs * 2} points for {pairs} pairs");
            }

            // Runs
            int runPoints = CountRuns(hand);
            if (runPoints > 0)
            {
                points += runPoints;
                AddMessage($"{player.Name}'s {handType}: {runPoints} points for runs");
            }

            // Flush
            int flushPoints = CountFlush(hand, isCrib);
            if (flushPoints > 0)
            {
                points += flushPoints;
                AddMessage($"{player.Name}'s {handType}: {flushPoints} points for flush");
            }

            // Nobs (Jack of same suit as cut card)
            if (CutCard != null)
            {
                foreach (var card in hand)
                {
                    if (card.Rank == "J" && card.Suit == CutCard.Suit)
                    {
                        points += 1;
                        AddMessage($"{player.Name}'s {handType}: 1 point for nobs");
                    }
                }
            }

            player.Score += points;
            AddMessage($"{player.Name} scores {points} points from {handType}");
        }

        private int CountFifteens(List<Card> hand)
        {
            var allCards = new List<Card>(hand);
            if (CutCard != null) allCards.Add(CutCard);

            int count = 0;
            // Check all combinations
            for (int i = 0; i < (1 << allCards.Count); i++)
            {
                int sum = 0;
                for (int j = 0; j < allCards.Count; j++)
                {
                    if ((i & (1 << j)) != 0)
                    {
                        sum += allCards[j].Value;
                    }
                }
                if (sum == 15) count++;
            }
            return count;
        }

        private int CountPairs(List<Card> hand)
        {
            var allCards = new List<Card>(hand);
            if (CutCard != null) allCards.Add(CutCard);

            int count = 0;
            for (int i = 0; i < allCards.Count; i++)
            {
                for (int j = i + 1; j < allCards.Count; j++)
                {
                    if (allCards[i].Rank == allCards[j].Rank)
                    {
                        count++;
                    }
                }
            }
            return count;
        }

        private int CountRuns(List<Card> hand)
        {
            var allCards = new List<Card>(hand);
            if (CutCard != null) allCards.Add(CutCard);

            // Try to find longest runs
            for (int len = allCards.Count; len >= 3; len--)
            {
                var runCount = 0;
                // Check all combinations of this length
                foreach (var combo in GetCombinations(allCards, len))
                {
                    var sorted = combo.OrderBy(c => c.RankValue).ToList();
                    bool isRun = true;
                    for (int i = 1; i < sorted.Count; i++)
                    {
                        if (sorted[i].RankValue != sorted[i - 1].RankValue + 1)
                        {
                            isRun = false;
                            break;
                        }
                    }
                    if (isRun) runCount++;
                }
                if (runCount > 0) return runCount * len;
            }
            return 0;
        }

        private IEnumerable<List<T>> GetCombinations<T>(List<T> list, int length)
        {
            if (length == 0) yield return new List<T>();
            else
            {
                for (int i = 0; i <= list.Count - length; i++)
                {
                    foreach (var combo in GetCombinations(list.Skip(i + 1).ToList(), length - 1))
                    {
                        yield return new List<T> { list[i] }.Concat(combo).ToList();
                    }
                }
            }
        }

        private int CountFlush(List<Card> hand, bool isCrib)
        {
            if (hand.Count == 0) return 0;

            string suit = hand[0].Suit;
            bool allSame = hand.All(c => c.Suit == suit);

            if (!allSame) return 0;

            // For crib, all 5 cards (including cut) must match
            // For hand, 4 cards matching is worth 4, or 5 if cut matches
            if (isCrib)
            {
                return CutCard?.Suit == suit ? 5 : 0;
            }
            else
            {
                return CutCard?.Suit == suit ? 5 : 4;
            }
        }

        private void AddMessage(string message)
        {
            MessageAdded?.Invoke(message);
        }
    }
}
