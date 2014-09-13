require 'rubygems'
require 'sinatra'

set :sessions, true

helpers do
  
  def calculate_total(cards) 
  # [['H', '3'], ['S', 'Q'], ... ]
    arr = cards.map {|i| i[1] }
    total = 0
    arr.each do |value|
      if value == "A"
        total += 11
      elsif value.to_i == 0
        total += 10
      else
        total += value.to_i 
      end
    end

    arr.count("A").times do
      total -= 10  if total > 21
    end

    total
  end

  def display_card(card)
      suit = case card[0]
              when 'H' then 'hearts'
              when 'D' then 'diamonds'
              when 'S' then 'spades'
              when 'C' then 'clubs'
            end

      value = case card[1]
                when 'A' then 'ace'
                when 'J' then 'jack'
                when 'K' then 'king'
                when 'Q' then 'queen'
                else value = card[1]
              end
      return "<img src='/images/cards/#{suit}_#{value}.jpg'>"
  end

  def check_name(name)
    if /[0-9\W]/.match(name)
      @error = "Name must be letters only."
      erb :new_player
    elsif name.empty?
      @error = "Name cannot be blank."
      erb :new_player
    else
      session[:player_name] = name
      redirect '/bet'
    end
  end

  def check_bet(amount)
    if /[a-zA-Z\W]/.match(amount)
      @error = "Enter numbers only."
    elsif amount.to_i > session[:bank_roll]
      @error = "Bet must be less than or equal to #{session[:bank_roll]}."
    else
      session[:bet_amount] = amount
      redirect '/game'
    end
  end

  def initial_hand_check(dealer_cards, player_cards)
    if calculate_total(dealer_cards) == 21 && calculate_total(player_cards) == 21
      @show_hit_or_stand_buttons = false
      @info = "You and the dealer have 21. It's a tie! <a href='/bet'>Play again?</a>"
    elsif calculate_total(player_cards) == 21
      @show_hit_or_stand_buttons = false
      @success = "You have blackjack! You win! <a href='/bet'>Play again?</a>"
       session[:bank_roll] = session[:bank_roll] + (session[:bet_amount].to_i * 1.50)
    elsif calculate_total(dealer_cards) == 21
      @show_hit_or_stand_buttons = false
      @error = "Dealer has blackjack. You lose! <a href='/bet'>Play again?</a>"
      session[:bank_roll] -= session[:bet_amount].to_i
    else
      @info = "Would you like to Hit or Stand, #{session[:player_name]}?"
    end
  end

  def check_player_hand(player_cards)
    if calculate_total(player_cards) > 21
      @show_hit_or_stand_buttons = false
      @error = "Oops! You busted! <a href='/bet'>Play again?</a>"
      session[:bank_roll] -= session[:bet_amount].to_i
    elsif calculate_total(player_cards) == 21
      @show_hit_or_stand_buttons = false
      @info = "You have 21. Dealer's turn to draw."
      redirect "/game/dealer"
     else
      @info = "Would you like to Hit or Stand, #{session[:player_name]}?"
    end
  end

  def check_dealer_hand(dealer_cards)
    if calculate_total(dealer_cards) > 21
      @success = "Dealer busted. You win! <a href='/bet'>Play again?</a>"
      session[:bank_roll] += session[:bet_amount].to_i
    elsif calculate_total(dealer_cards) >= 17
      redirect "/compare"
    else
      redirect "/game/dealer"
    end
  end

  def final_hand_check(dealer_cards, player_cards)
    if calculate_total(dealer_cards) > calculate_total(player_cards)
      @error = "The dealer has #{calculate_total(dealer_cards)}. You have #{calculate_total(player_cards)}. You lose. <a href='/bet'>Play again?</a>"
      session[:bank_roll] -= session[:bet_amount].to_i
    elsif calculate_total(dealer_cards) < calculate_total(player_cards)
      @success = "The dealer has #{calculate_total(dealer_cards)}. You have #{calculate_total(player_cards)}. You win! <a href='/bet'>Play again?</a>"
      session[:bank_roll] += session[:bet_amount].to_i
    else
      @info = "The dealer has #{calculate_total(dealer_cards)}. You have #{calculate_total(player_cards)}. It's a tie. <a href='/bet'>Play again?</a>"
    end
  end

  def bank_check(amount)
    if amount == 0
      @error = "You are out of money <a href='/new_player'>Play again?</a>"
    end
  end

end

before do
  @show_hit_or_stand_buttons = true
end

get '/' do
  if session[:player_name]
    redirect "/game"
  else
    redirect "/new_player"
  end
end

get "/new_player" do
  session.clear
  erb :new_player
end

post '/set_name' do
  check_name(params[:player_name])
end

get '/bet' do
  @show_bet_form = true

  if session[:bet_amount] != nil
    session[:bank_roll]
    if session[:bank_roll] == 0
      @error = "You are out of money <a href='/new_player'>Start Over?</a>"
      @show_bet_form = false
    end
  else
    session[:bank_roll] = 500
  end
  erb :bet
end

post '/set_bet' do
  @show_bet_form = true
  check_bet(params[:bet_amount])

  erb :bet
end

get '/game' do
  #create a deck
  suits = ['H', 'S', 'C', 'D']
  values = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K']
  
  session[:deck] = suits.product(values).shuffle!

  # prettify cards

  session[:player_cards] = []
  session[:dealer_cards] = []

  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop


  # check of initial deal
  initial_hand_check(session[:dealer_cards],session[:player_cards])
  erb :game
end

post "/game/player/hit" do
  session[:player_cards] << session[:deck].pop

  check_player_hand(session[:player_cards])
  
  erb :game
end

post "/game/player/stand" do
    redirect "/game/dealer"
end

get "/game/dealer" do
  @success = "You are standing with #{calculate_total(session[:player_cards])}."
  @show_hit_or_stand_buttons = false
  @show_dealers_cards = true

  if calculate_total(session[:dealer_cards]) <= 16
    @show_dealer_button = true
  else
    redirect "/compare"
  end

  erb :game
end

post "/game/dealer/draw" do
  @show_dealers_cards = true
  @show_hit_or_stand_buttons = false

  session[:dealer_cards] << session[:deck].pop

  @dealer_draw = true

  check_dealer_hand(session[:dealer_cards])

  erb :game
end

get "/compare" do
  @show_hit_or_stand_buttons = false
  @show_dealers_cards = true

  if session[:dealer_cards].size > 2
    @dealer_draw = true
  end

  final_hand_check(session[:dealer_cards], session[:player_cards])

  erb :game 
end
