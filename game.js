// Card and Game Classes
class Card {
    constructor(rank, suit) {
        this.rank = rank;
        this.suit = suit;
    }

    get value() {
        const rankValue = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'].indexOf(this.rank) + 1;
        return rankValue >= 10 ? 10 : rankValue;
    }

    get rankValue() {
        // For sorting purposes: Ace=1, 2=2, ..., King=13
        return ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'].indexOf(this.rank) + 1;
    }

    get name() {
        const rankNames = {
            'A': 'Ace', '2': 'Two', '3': 'Three', '4': 'Four', '5': 'Five',
            '6': 'Six', '7': 'Seven', '8': 'Eight', '9': 'Nine', '10': 'Ten',
            'J': 'Jack', 'Q': 'Queen', 'K': 'King'
        };
        const suitNames = {'♥': 'Hearts', '♦': 'Diamonds', '♣': 'Clubs', '♠': 'Spades'};
        return `${rankNames[this.rank]} of ${suitNames[this.suit]}`;
    }

    get suitSymbol() {
        return this.suit;
    }

    get isRed() {
        return this.suit === '♥' || this.suit === '♦';
    }

    toString() {
        return this.name;
    }
}

class Deck {
    constructor() {
        this.cards = [];
        const suits = ['♥', '♦', '♣', '♠'];
        const ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];
        
        for (const suit of suits) {
            for (const rank of ranks) {
                this.cards.push(new Card(rank, suit));
            }
        }
        this.shuffle();
    }

    shuffle() {
        for (let i = this.cards.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [this.cards[i], this.cards[j]] = [this.cards[j], this.cards[i]];
        }
    }

    deal() {
        return this.cards.pop();
    }
}

class Player {
    constructor(name, isComputer = false) {
        this.name = name;
        this.hand = [];
        this.playedCards = [];
        this.score = 0;
        this.isComputer = isComputer;
    }

    addCard(card) {
        this.hand.push(card);
    }

    removeCard(card) {
        const index = this.hand.indexOf(card);
        if (index > -1) {
            return this.hand.splice(index, 1)[0];
        }
        return null;
    }

    playCard(card) {
        const removed = this.removeCard(card);
        if (removed) {
            this.playedCards.push(removed);
        }
        return removed;
    }

    clearPlayedCards() {
        this.playedCards = [];
    }

    resetHand() {
        this.hand = [];
        this.playedCards = [];
    }

    sortHand() {
        this.hand.sort((a, b) => a.rankValue - b.rankValue);
    }
}

// Game Logic
class CribbageGame {
    constructor() {
        this.player = new Player('Player', false);
        this.computer = new Player('Computer', true);
        this.deck = null;
        this.crib = [];
        this.cutCard = null;
        this.dealer = null;
        this.currentTurn = null;
        this.playedPile = [];
        this.currentCount = 0;
        this.state = 'CUT_FOR_DEAL';
        this.selectedForDiscard = new Set();
        this.messageListeners = [];
        this.goCount = 0;
    }

    addMessageListener(callback) {
        this.messageListeners.push(callback);
    }

    addMessage(message) {
        this.messageListeners.forEach(cb => cb(message));
    }

    startNewGame() {
        this.player.score = 0;
        this.computer.score = 0;
        this.state = 'CUT_FOR_DEAL';
        this.addMessage('New game started. Click Cut for Deal to begin.');
    }

    cutForDeal() {
        if (this.state !== 'CUT_FOR_DEAL') return;

        const deck1 = new Deck();
        const deck2 = new Deck();
        
        const playerCut = deck1.deal();
        const computerCut = deck2.deal();

        this.addMessage(`You cut: ${playerCut}`);
        this.addMessage(`Computer cut: ${computerCut}`);

        if (playerCut.value < computerCut.value) {
            this.dealer = this.player;
            this.addMessage('You are the dealer!');
        } else if (computerCut.value < playerCut.value) {
            this.dealer = this.computer;
            this.addMessage('Computer is the dealer.');
        } else {
            this.addMessage('Tie! Cut again.');
            return;
        }

        this.startRound();
    }

    getCutForDealAnnouncement() {
        // Returns the batched announcement for cut for deal
        // This will be called by GameUI to provide a combined announcement
        return this.lastCutAnnouncement;
    }

    startRound() {
        this.player.resetHand();
        this.computer.resetHand();
        this.crib = [];
        this.cutCard = null;
        this.playedPile = [];
        this.currentCount = 0;
        this.selectedForDiscard.clear();
        this.goCount = 0;

        this.deck = new Deck();
        
        // Deal 6 cards to each player
        for (let i = 0; i < 6; i++) {
            this.player.addCard(this.deck.deal());
            this.computer.addCard(this.deck.deal());
        }

        this.state = 'DISCARD';
        this.addMessage('Deal complete. Select 2 cards to discard to the crib.');
        this.addMessage(this.dealer === this.player ? "Player's crib." : "Computer's crib.");
    }

    discardToCrib(playerIndices) {
        if (this.state !== 'DISCARD') return;

        // Player discards
        const playerDiscards = playerIndices.map(i => this.player.hand[i]).filter(c => c);
        playerDiscards.sort((a, b) => this.player.hand.indexOf(b) - this.player.hand.indexOf(a));
        
        for (const card of playerDiscards) {
            const removed = this.player.removeCard(card);
            if (removed) this.crib.push(removed);
        }

        // Computer discards (simple strategy: discard first 2 cards)
        for (let i = 0; i < 2; i++) {
            if (this.computer.hand.length > 0) {
                const card = this.computer.hand[0];
                this.computer.removeCard(card);
                this.crib.push(card);
            }
        }

        // Cut card
        this.cutCard = this.deck.deal();
        this.addMessage(`Cut card: ${this.cutCard}`);

        // Check for his heels (Jack cut)
        if (this.cutCard.rank === 'J') {
            this.dealer.score += 2;
            this.addMessage(`${this.dealer.name} scores 2 for his heels!`);
            // Check for immediate win (rare but possible)
            if (this.checkForWinner()) {
                return;
            }
        }

        // Start play phase
        this.state = 'PLAY';
        this.currentTurn = this.dealer === this.player ? this.computer : this.player;
        this.addMessage(`${this.currentTurn.name} plays first.`);
    }

    playCard(player, card) {
        if (this.state !== 'PLAY') return false;
        if (this.currentTurn !== player) return false;
        if (player.playedCards.includes(card)) return false;
        if (this.currentCount + card.value > 31) return false;

        player.playCard(card);
        this.playedPile.push({card, player});
        this.currentCount += card.value;

        const points = this.scorePlay(card, player);
        if (points > 0) {
            player.score += points;
            // Check for immediate win
            if (this.checkForWinner()) {
                return true;
            }
        }

        this.addMessage(`${player.name} plays ${card} (Count: ${this.currentCount})`);

        // If 31, pause for user to continue
        if (this.currentCount === 31) {
            this.currentCount = 0;
            this.playedPile = [];
            this.state = 'PAUSE_31';
            this.addMessage('Count reset. Click Continue to resume play.');
            return true;
        }

        // Check for end of play
        if (this.checkPlayComplete()) {
            this.endPlay();
            return true;
        }

        // Switch turns
        this.switchTurn();
        return true;
    }

    scorePlay(card, player) {
        let points = 0;
        const messages = [];

        // 15
        if (this.currentCount === 15) {
            points += 2;
            messages.push('15 for 2');
        }

        // 31
        if (this.currentCount === 31) {
            points += 2;
            messages.push('31 for 2');
        }

        // Pairs, three of a kind, four of a kind
        const recentCards = this.playedPile.slice(-4).map(p => p.card);
        if (recentCards.length >= 2) {
            let pairCount = 1;
            for (let i = recentCards.length - 2; i >= 0; i--) {
                if (recentCards[i].rank === card.rank) {
                    pairCount++;
                } else {
                    break;
                }
            }

            if (pairCount === 2) {
                points += 2;
                messages.push('Pair for 2');
            } else if (pairCount === 3) {
                points += 6;
                messages.push('Three of a kind for 6');
            } else if (pairCount === 4) {
                points += 12;
                messages.push('Four of a kind for 12');
            }
        }

        // Runs (3 or more cards in sequence)
        if (recentCards.length >= 3) {
            for (let len = recentCards.length; len >= 3; len--) {
                const checkCards = recentCards.slice(-len);
                if (this.isRun(checkCards)) {
                    points += len;
                    messages.push(`Run of ${len} for ${len}`);
                    break;
                }
            }
        }

        if (messages.length > 0) {
            this.addMessage(`${player.name} scores ${points} (${messages.join(', ')})`);
        }

        return points;
    }

    isRun(cards) {
        const ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];
        const values = cards.map(c => ranks.indexOf(c.rank)).sort((a, b) => a - b);
        
        for (let i = 1; i < values.length; i++) {
            if (values[i] !== values[i - 1] + 1) {
                return false;
            }
        }
        return true;
    }

    canPlay(player) {
        return player.hand.some(card => 
            !player.playedCards.includes(card) && 
            this.currentCount + card.value <= 31
        );
    }

    sayGo() {
        if (!this.canPlay(this.currentTurn)) {
            this.addMessage(`${this.currentTurn.name} says Go.`);
            
            const opponent = this.currentTurn === this.player ? this.computer : this.player;
            
            if (!this.canPlay(opponent)) {
                // Both players can't play - award go point
                const lastPlayer = this.playedPile[this.playedPile.length - 1]?.player;
                if (lastPlayer) {
                    lastPlayer.score += 1;
                    this.addMessage(`${lastPlayer.name} scores 1 for go.`);
                    // Check for immediate win
                    if (this.checkForWinner()) {
                        return;
                    }
                }
                
                // Reset count
                this.currentCount = 0;
                this.playedPile = [];
                
                if (this.checkPlayComplete()) {
                    this.endPlay();
                } else {
                    // After a go, the player who said go first gets to lead next
                    // That's the opponent of the player who got the go point
                    this.currentTurn = lastPlayer === this.player ? this.computer : this.player;
                }
            } else {
                this.currentTurn = opponent;
            }
        }
    }

    switchTurn() {
        const opponent = this.currentTurn === this.player ? this.computer : this.player;
        
        if (this.canPlay(opponent)) {
            this.currentTurn = opponent;
        } else if (this.canPlay(this.currentTurn)) {
            // Opponent can't play, current player continues
            this.addMessage(`${opponent.name} says Go.`);
        } else {
            // Neither can play
            const lastPlayer = this.playedPile[this.playedPile.length - 1]?.player;
            if (lastPlayer && this.currentCount > 0 && this.currentCount !== 31) {
                lastPlayer.score += 1;
                this.addMessage(`${lastPlayer.name} scores 1 for go.`);
                // Check for immediate win
                if (this.checkForWinner()) {
                    return;
                }
            }
            
            this.currentCount = 0;
            this.playedPile = [];
            
            // After a go, the player who said go first gets to lead next
            // That's the opponent of the player who got the go point
            if (lastPlayer) {
                this.currentTurn = lastPlayer === this.player ? this.computer : this.player;
            }
        }
    }

    checkPlayComplete() {
        return this.player.playedCards.length === 4 && this.computer.playedCards.length === 4;
    }

    endPlay() {
        this.addMessage('Play phase complete. Click Continue to count hands.');
        this.state = 'PAUSE_BEFORE_COUNT';
    }

    countHands() {
        this.addMessage('Counting hands...');
        
        // Score hands - use playedCards since all cards have been played
        const nonDealer = this.dealer === this.player ? this.computer : this.player;
        
        // Non-dealer scores first
        const nonDealerScore = this.scoreHand(nonDealer.playedCards, this.cutCard, false);
        nonDealer.score += nonDealerScore;
        this.addMessage(`${nonDealer.name} scores ${nonDealerScore} from hand.`);
        
        // Check for winner after non-dealer scores
        if (this.checkForWinner()) {
            return;
        }
        
        // Dealer scores
        const dealerScore = this.scoreHand(this.dealer.playedCards, this.cutCard, false);
        this.dealer.score += dealerScore;
        this.addMessage(`${this.dealer.name} scores ${dealerScore} from hand.`);
        
        // Check for winner after dealer scores hand
        if (this.checkForWinner()) {
            return;
        }
        
        // Dealer scores crib
        const cribScore = this.scoreHand(this.crib, this.cutCard, true);
        this.dealer.score += cribScore;
        this.addMessage(`${this.dealer.name} scores ${cribScore} from crib.`);
        
        // Check for winner after crib
        if (this.checkForWinner()) {
            return;
        }
        
        // Switch dealer
        this.dealer = this.dealer === this.player ? this.computer : this.player;
        this.state = 'ROUND_OVER';
    }

    checkForWinner() {
        if (this.player.score >= 121) {
            this.addMessage('You win!');
            this.state = 'GAME_OVER';
            return true;
        } else if (this.computer.score >= 121) {
            this.addMessage('Computer wins!');
            this.state = 'GAME_OVER';
            return true;
        }
        return false;
    }

    scoreHand(hand, cutCard, isCrib) {
        const cards = [...hand];
        if (cutCard) cards.push(cutCard);
        
        let score = 0;

        // 15s
        for (let i = 0; i < (1 << cards.length); i++) {
            const subset = [];
            for (let j = 0; j < cards.length; j++) {
                if (i & (1 << j)) subset.push(cards[j]);
            }
            if (subset.length >= 2 && subset.reduce((sum, c) => sum + c.value, 0) === 15) {
                score += 2;
            }
        }

        // Pairs
        for (let i = 0; i < cards.length; i++) {
            for (let j = i + 1; j < cards.length; j++) {
                if (cards[i].rank === cards[j].rank) {
                    score += 2;
                }
            }
        }

        // Runs
        const runScore = this.findBestRun(cards);
        score += runScore;

        // Flush
        if (hand.every(c => c.suit === hand[0].suit)) {
            if (isCrib) {
                if (cutCard && cutCard.suit === hand[0].suit) {
                    score += 5;
                }
            } else {
                score += 4;
                if (cutCard && cutCard.suit === hand[0].suit) {
                    score += 1;
                }
            }
        }

        // Nobs (Jack of same suit as cut card)
        if (cutCard) {
            for (const card of hand) {
                if (card.rank === 'J' && card.suit === cutCard.suit) {
                    score += 1;
                }
            }
        }

        return score;
    }

    findBestRun(cards) {
        const ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];
        let maxScore = 0;

        for (let len = 5; len >= 3; len--) {
            for (let i = 0; i < (1 << cards.length); i++) {
                const subset = [];
                for (let j = 0; j < cards.length; j++) {
                    if (i & (1 << j)) subset.push(cards[j]);
                }
                
                if (subset.length === len) {
                    const values = subset.map(c => ranks.indexOf(c.rank)).sort((a, b) => a - b);
                    let isRun = true;
                    for (let k = 1; k < values.length; k++) {
                        if (values[k] !== values[k - 1] + 1) {
                            isRun = false;
                            break;
                        }
                    }
                    if (isRun) {
                        maxScore = Math.max(maxScore, len);
                    }
                }
            }
            if (maxScore > 0) break;
        }

        return maxScore;
    }
}

// UI Controller
class GameUI {
    constructor() {
        this.game = new CribbageGame();
        this.currentCardIndex = 0;
        this.announcementQueue = [];
        this.announcementTimeout = null;
        this.suppressIndividualAnnouncements = false;
        this.initializeElements();
        this.setupEventListeners();
        this.setupKeyboardNavigation();
        this.game.addMessageListener(msg => this.addStatusMessage(msg));
        this.game.startNewGame();
        this.updateUI();
    }

    initializeElements() {
        this.elements = {
            playerScore: document.getElementById('playerScore'),
            computerScore: document.getElementById('computerScore'),
            currentCount: document.getElementById('currentCount'),
            playCountDisplay: document.getElementById('playCountDisplay'),
            playerHand: document.getElementById('playerHand'),
            computerHand: document.getElementById('computerHand'),
            cribHeading: document.getElementById('cribHeading'),
            cribCards: document.getElementById('cribCards'),
            playedCards: document.getElementById('playedCards'),
            statusMessages: document.getElementById('statusMessages'),
            cutButton: document.getElementById('cutButton'),
            discardButton: document.getElementById('discardButton'),
            goButton: document.getElementById('goButton'),
            continueButton: document.getElementById('continueButton'),
            liveAnnouncer: document.getElementById('liveAnnouncer'),
            playerTrack: document.getElementById('playerTrack'),
            computerTrack: document.getElementById('computerTrack')
        };

        // Create peg tracks
        this.createPegTrack(this.elements.playerTrack);
        this.createPegTrack(this.elements.computerTrack);
    }

    createPegTrack(container) {
        const peg = document.createElement('div');
        peg.className = 'peg';
        peg.style.left = '0%';
        container.appendChild(peg);
    }

    setupEventListeners() {
        this.elements.cutButton.addEventListener('click', () => this.handleCut());
        this.elements.discardButton.addEventListener('click', () => this.handleDiscard());
        this.elements.goButton.addEventListener('click', () => this.handleGo());
        this.elements.continueButton.addEventListener('click', () => this.handleContinue());
    }

    setupKeyboardNavigation() {
        this.elements.playerHand.addEventListener('keydown', (e) => {
            const cards = Array.from(this.elements.playerHand.children);
            if (cards.length === 0) return;

            if (e.key === 'ArrowLeft') {
                e.preventDefault();
                this.currentCardIndex = Math.max(0, this.currentCardIndex - 1);
                this.updateCardFocus();
            } else if (e.key === 'ArrowRight') {
                e.preventDefault();
                this.currentCardIndex = Math.min(cards.length - 1, this.currentCardIndex + 1);
                this.updateCardFocus();
            } else if (e.key === ' ' || e.key === 'Enter') {
                e.preventDefault();
                this.handleCardAction(this.currentCardIndex);
            }
        });

        // Focus management for status messages list
        this.elements.statusMessages.addEventListener('focus', (e) => {
            const messages = Array.from(this.elements.statusMessages.querySelectorAll('li'));
            if (messages.length === 0) return;
            
            // If focus is on the ul itself (from tabbing), move focus to first item
            if (e.target === this.elements.statusMessages) {
                messages[0].focus();
            }
        });

        // Keyboard navigation for status messages list
        this.elements.statusMessages.addEventListener('keydown', (e) => {
            const messages = Array.from(this.elements.statusMessages.querySelectorAll('li'));
            if (messages.length === 0) return;

            const currentIndex = messages.indexOf(document.activeElement);
            
            if (e.key === 'ArrowDown') {
                e.preventDefault();
                const nextIndex = currentIndex < messages.length - 1 ? currentIndex + 1 : currentIndex;
                if (messages[nextIndex]) messages[nextIndex].focus();
            } else if (e.key === 'ArrowUp') {
                e.preventDefault();
                const prevIndex = currentIndex > 0 ? currentIndex - 1 : 0;
                if (messages[prevIndex]) messages[prevIndex].focus();
            } else if (e.key === 'Home') {
                e.preventDefault();
                if (messages[0]) messages[0].focus();
            } else if (e.key === 'End') {
                e.preventDefault();
                if (messages[messages.length - 1]) messages[messages.length - 1].focus();
            }
        });
    }

    updateCardFocus() {
        const cards = Array.from(this.elements.playerHand.children);
        cards.forEach((card, i) => {
            card.classList.toggle('focused', i === this.currentCardIndex);
            // Update tabindex for roving tabindex pattern
            card.setAttribute('tabindex', i === this.currentCardIndex ? '0' : '-1');
        });
        
        if (cards[this.currentCardIndex]) {
            // Move actual keyboard focus to the current card
            // Screen reader will announce aria-label which includes position
            cards[this.currentCardIndex].focus();
        }
    }

    handleCardAction(index) {
        const card = this.game.player.hand[index];
        if (!card) return;

        if (this.game.state === 'DISCARD') {
            if (this.game.selectedForDiscard.has(index)) {
                this.game.selectedForDiscard.delete(index);
                this.announce(`${card.name} unselected. ${this.game.selectedForDiscard.size} of 2 selected.`);
            } else if (this.game.selectedForDiscard.size < 2) {
                this.game.selectedForDiscard.add(index);
                this.announce(`${card.name} selected. ${this.game.selectedForDiscard.size} of 2 selected.`);
            } else {
                this.announce('Already have 2 cards selected. Unselect a card first.');
            }
            this.updateUI();
        } else if (this.game.state === 'PLAY' && this.game.currentTurn === this.game.player) {
            if (!this.game.player.playedCards.includes(card) && this.game.currentCount + card.value <= 31) {
                this.game.playCard(this.game.player, card);
                // Adjust currentCardIndex after playing a card
                // If we played the card at or before current index, shift focus left
                if (index <= this.currentCardIndex && this.currentCardIndex > 0) {
                    this.currentCardIndex--;
                }
                // Make sure index is still valid
                this.currentCardIndex = Math.min(this.currentCardIndex, this.game.player.hand.length - 1);
                this.updateUI();
                setTimeout(() => this.computerPlay(), 1000);
            } else {
                this.announce('Cannot play that card - would exceed 31.');
            }
        }
    }

    handleCut() {
        // Suppress individual announcements and collect them for batching
        this.suppressIndividualAnnouncements = true;
        const messagesBefore = this.elements.statusMessages.children.length;
        
        this.game.cutForDeal();
        this.updateUI();
        
        // Re-enable individual announcements
        this.suppressIndividualAnnouncements = false;
        
        // Batch announce the cut results
        const messagesAfter = this.elements.statusMessages.children.length;
        const newMessageCount = messagesAfter - messagesBefore;
        
        if (newMessageCount > 0) {
            const messages = [];
            for (let i = 0; i < newMessageCount && i < this.elements.statusMessages.children.length; i++) {
                messages.push(this.elements.statusMessages.children[i].textContent);
            }
            // Queue all messages and batch them
            messages.reverse().forEach(msg => this.queueAnnouncement(msg));
            this.batchAnnounce(150);
        }
        
        if (this.game.state === 'DISCARD') {
            setTimeout(() => this.elements.playerHand.focus(), 100);
        }
    }

    handleDiscard() {
        if (this.game.selectedForDiscard.size === 2) {
            const indices = Array.from(this.game.selectedForDiscard).sort((a, b) => b - a);
            this.game.discardToCrib(indices);
            this.currentCardIndex = 0;
            this.updateUI();
            
            if (this.game.currentTurn === this.game.computer) {
                setTimeout(() => this.computerPlay(), 1000);
            }
        }
    }

    handleGo() {
        this.game.sayGo();
        this.updateUI();
        if (this.game.currentTurn === this.game.computer) {
            setTimeout(() => this.computerPlay(), 1000);
        }
    }

    handleContinue() {
        if (this.game.state === 'PAUSE_BEFORE_COUNT') {
            this.game.countHands();
            this.updateUI();
        } else if (this.game.state === 'PAUSE_31') {
            this.game.state = 'PLAY';
            this.updateUI();
            if (this.game.currentTurn === this.game.computer) {
                setTimeout(() => this.computerPlay(), 1000);
            }
        } else if (this.game.state === 'ROUND_OVER') {
            this.game.startRound();
            this.currentCardIndex = 0;
            this.updateUI();
        }
    }

    computerPlay() {
        if (this.game.state !== 'PLAY' || this.game.currentTurn !== this.game.computer) return;

        const playableCards = this.game.computer.hand.filter(card =>
            !this.game.computer.playedCards.includes(card) &&
            this.game.currentCount + card.value <= 31
        );

        if (playableCards.length > 0) {
            this.game.playCard(this.game.computer, playableCards[0]);
            this.updateUI();
            
            if (this.game.state === 'PLAY' && this.game.currentTurn === this.game.computer) {
                setTimeout(() => this.computerPlay(), 1000);
            }
        } else {
            this.game.sayGo();
            this.updateUI();
        }
    }

    updateUI() {
        // Update scores
        this.elements.playerScore.textContent = this.game.player.score;
        this.elements.computerScore.textContent = this.game.computer.score;
        this.elements.currentCount.textContent = this.game.currentCount;

        // Update play count display in played cards area
        if (this.game.state === 'PLAY' && this.game.currentCount > 0) {
            this.elements.playCountDisplay.textContent = `Count: ${this.game.currentCount}`;
        } else {
            this.elements.playCountDisplay.textContent = '';
        }

        // Update peg positions
        this.updatePegPosition(this.elements.playerTrack, this.game.player.score);
        this.updatePegPosition(this.elements.computerTrack, this.game.computer.score);

        // Update crib heading
        if (this.game.dealer) {
            const cribOwner = this.game.dealer === this.game.player ? "Player's Crib" : "Computer's Crib";
            this.elements.cribHeading.textContent = cribOwner;
            this.elements.cribCards.setAttribute('aria-label', cribOwner);
        } else {
            this.elements.cribHeading.textContent = 'The Crib';
            this.elements.cribCards.setAttribute('aria-label', 'The crib');
        }

        // Update hands
        this.renderPlayerHand();
        this.renderComputerHand();
        this.renderCrib();
        this.renderPlayedCards();
        
        // Restore focus to current card after re-rendering
        const cards = Array.from(this.elements.playerHand.children);
        if (cards[this.currentCardIndex]) {
            cards[this.currentCardIndex].focus();
        }

        // Update buttons
        this.elements.cutButton.disabled = this.game.state !== 'CUT_FOR_DEAL';
        this.elements.discardButton.disabled = this.game.state !== 'DISCARD' || this.game.selectedForDiscard.size !== 2;
        this.elements.discardButton.textContent = `Discard (${this.game.selectedForDiscard.size}/2)`;
        this.elements.goButton.disabled = this.game.state !== 'PLAY' || !this.game.canPlay(this.game.player);
        this.elements.continueButton.disabled = this.game.state !== 'ROUND_OVER' && this.game.state !== 'PAUSE_BEFORE_COUNT' && this.game.state !== 'PAUSE_31';
    }

    updatePegPosition(track, score) {
        const peg = track.querySelector('.peg');
        if (peg) {
            const percentage = Math.min((score / 121) * 100, 100);
            peg.style.left = `${percentage}%`;
            
            // Update ARIA attributes for accessibility
            track.setAttribute('aria-valuenow', score);
            
            // Announce score changes to screen readers
            const isPlayer = track.id === 'playerTrack';
            const label = isPlayer ? 'Player' : 'Computer';
            const announcement = document.getElementById('scoreAnnouncement');
            if (announcement && score > 0) {
                announcement.textContent = `${label} score: ${score}`;
            }
        }
    }

    renderPlayerHand() {
        this.elements.playerHand.innerHTML = '';
        // Sort the hand before displaying (aces low)
        this.game.player.sortHand();
        this.game.player.hand.forEach((card, index) => {
            const cardElement = this.createCardElement(card, true);
            
            // Use proper ARIA attributes for position in set
            cardElement.setAttribute('aria-setsize', this.game.player.hand.length);
            cardElement.setAttribute('aria-posinset', index + 1);
            
            // Handle selection state for discard phase
            if (this.game.state === 'DISCARD' && this.game.selectedForDiscard.has(index)) {
                cardElement.classList.add('selected');
                cardElement.setAttribute('aria-pressed', 'true');
            } else {
                cardElement.setAttribute('aria-pressed', 'false');
            }
            
            if (this.game.player.playedCards.includes(card)) {
                cardElement.classList.add('played');
            }
            
            if (index === this.currentCardIndex) {
                cardElement.classList.add('focused');
                // Make current card tabbable (roving tabindex pattern)
                cardElement.setAttribute('tabindex', '0');
            } else {
                // Other cards not in tab order but can receive programmatic focus
                cardElement.setAttribute('tabindex', '-1');
            }
            
            cardElement.addEventListener('click', () => this.handleCardAction(index));
            this.elements.playerHand.appendChild(cardElement);
        });
    }

    renderComputerHand() {
        this.elements.computerHand.innerHTML = '';
        // Show card backs for remaining cards in computer's hand
        const count = this.game.computer.hand.length;
        
        for (let i = 0; i < count; i++) {
            const cardElement = this.createCardElement(null, false);
            this.elements.computerHand.appendChild(cardElement);
        }
    }

    renderCrib() {
        this.elements.cribCards.innerHTML = '';
        // Show face-down cards for the crib count
        for (let i = 0; i < this.game.crib.length; i++) {
            const cardElement = this.createCardElement(null, false);
            this.elements.cribCards.appendChild(cardElement);
        }
    }

    renderPlayedCards() {
        this.elements.playedCards.innerHTML = '';
        this.game.playedPile.forEach(({card, player}) => {
            const cardElement = this.createCardElement(card, true);
            cardElement.style.opacity = '0.8';
            this.elements.playedCards.appendChild(cardElement);
        });
    }

    createCardElement(card, faceUp) {
        const cardDiv = document.createElement('div');
        cardDiv.className = 'card';
        
        if (!faceUp || !card) {
            cardDiv.classList.add('card-back');
            return cardDiv;
        }

        const colorClass = card.isRed ? 'red' : 'black';
        
        cardDiv.innerHTML = `
            <div>
                <div class="card-rank ${colorClass}">${card.rank}</div>
                <div class="card-suit ${colorClass}">${card.suitSymbol}</div>
            </div>
            <div class="card-center ${colorClass}">${card.suitSymbol}</div>
            <div style="text-align: right;">
                <div class="card-rank ${colorClass}" style="transform: rotate(180deg);">${card.rank}</div>
                <div class="card-suit ${colorClass}" style="transform: rotate(180deg);">${card.suitSymbol}</div>
            </div>
        `;
        
        cardDiv.setAttribute('aria-label', card.name);
        cardDiv.setAttribute('role', 'button');
        cardDiv.setAttribute('tabindex', '-1');
        cardDiv.setAttribute('aria-pressed', 'false');
        
        return cardDiv;
    }

    addStatusMessage(message) {
        const messageItem = document.createElement('li');
        messageItem.className = 'status-message';
        messageItem.textContent = message;
        messageItem.setAttribute('tabindex', '-1');
        this.elements.statusMessages.insertBefore(messageItem, this.elements.statusMessages.firstChild);
        
        // Only announce immediately if not suppressing for batching
        if (!this.suppressIndividualAnnouncements) {
            this.announce(message);
        }
    }

    announce(message) {
        this.elements.liveAnnouncer.textContent = message;
        setTimeout(() => {
            this.elements.liveAnnouncer.textContent = '';
        }, 1000);
    }

    queueAnnouncement(message) {
        this.announcementQueue.push(message);
    }

    batchAnnounce(delay = 100) {
        // Clear any pending batch
        if (this.announcementTimeout) {
            clearTimeout(this.announcementTimeout);
        }

        // Wait for all announcements to queue, then deliver as one
        this.announcementTimeout = setTimeout(() => {
            if (this.announcementQueue.length > 0) {
                const batchedMessage = this.announcementQueue.join('. ');
                this.announce(batchedMessage);
                this.announcementQueue = [];
            }
            this.announcementTimeout = null;
        }, delay);
    }
}

// Initialize game when page loads
document.addEventListener('DOMContentLoaded', () => {
    new GameUI();
});
