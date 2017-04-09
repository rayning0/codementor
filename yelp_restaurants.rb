# https://www.oneinterview.io/sample
# Build a simple Yelp-like system: Given a set of restaurant and metadata (coordinates, ratings, opening hours), design and implement the following functionalities without using a database.

# 1. Find restaurants within specified radius, given a coordinate
# 2. Improve the above function by only returning restaurants that are open given desired dining hour
# 3. Improve the above function by sorting the results by average ratings

require 'rspec/autorun'

class Yelp
  R = 6371 # earth's radius (km)

  def initialize(restaurants = [], ratings = [])
    @restaurants = restaurants.sort_by { |restaurant| restaurant.id }
    @ratings = ratings.sort_by { |rating| rating.restaurant_id }
  end

  # Returns list of Restaurants within radius.
  #
  #  latitude: latitude in Float
  #  longitude: longitude in Float
  #  radius: kilometer in Fixnum
  #  dining_hour: If nil, find any restaurant in radius. Otherwise return list of open restaurants at specified hour.
  #  sort_by_rating: If true, sort result in descending order, highest rated first.
  #
  def to_rad(degree)
    degree * Math::PI / 180
  end

  # km between 2 points on globe
  # http://janmatuschek.de/LatitudeLongitudeBoundingCoordinates
  def dist_between(lat1, long1, lat2, long2)
    lat1 = to_rad(lat1)
    long1 = to_rad(long1)
    lat2 = to_rad(lat2)
    long2 = to_rad(long2)
    (Math.acos(Math.sin(lat1) * Math.sin(lat2) + Math.cos(lat1) * Math.cos(lat2) * Math.cos(long1 - long2)) * R).round(2)
  end

  # binary search, assuming @restaurants sorted by restaurant ID
  def get_rest(restaurant_id, restaurants = @restaurants)
    i = restaurants.size / 2
    restaurant = restaurants[i]
    return restaurant if restaurant.id == restaurant_id
    if restaurant.id < restaurant_id
      get_rest(restaurant_id, restaurants[i + 1..-1])
    else
      get_rest(restaurant_id, restaurants[0..i - 1])
    end
  end

  def rating(restaurant_id)
    @ratings.each do |rating|
      return rating.rating if rating.restaurant_id == restaurant_id
    end
  end

  def find(latitude, longitude, radius, dining_hour=nil, sort_by_rating=false)
    puts "Restaurants #{radius} km from #{latitude}, #{longitude}, open at #{dining_hour}. Rating sort: #{sort_by_rating}."
    result = []
    @restaurants.each do |restaurant|
      condition = dist_between(latitude, longitude, restaurant.lat, restaurant.long) < radius
      condition = condition && restaurant.open?(dining_hour) if dining_hour
      result << restaurant if condition
    end
    result.sort_by! { |restaurant| rating(restaurant.id) }.reverse! if sort_by_rating
    result.map do |r|
      {rating: rating(r.id), id: r.id, distance: dist_between(latitude, longitude, r.lat, r.long),
       name: r.name, open: r.open_hour, close: r.close_hour}
    end
  end
end

class Restaurant
  # where open_hour and close_hour is in [0-23]
  attr_reader :id, :name, :lat, :long, :open_hour, :close_hour

  def initialize(id, name, latitude, longitude, open_hour, close_hour)
    @id = id
    @name = name
    @lat = latitude
    @long = longitude
    @open_hour = open_hour
    @close_hour = close_hour
  end

  def open?(hour)
    return true if open_hour == close_hour || hour.between?(open_hour, close_hour)
    if close_hour < open_hour
      return (hour > close_hour && hour < open_hour) ? false : true
    end
    false
  end
end

class Rating
  # rating from 1-5
  attr_reader :restaurant_id, :rating

  def initialize(restaurant_id, rating)
    @restaurant_id = restaurant_id
    @rating = rating
  end
end

if __FILE__ == $0
  restaurants =  [Restaurant.new(3, "Big Wangs", 34.0566919, -118.2602324, 7, 23),
                  Restaurant.new(5, "Chipotle Mexican Grill", 34.0466919, -118.2602324, 10.5, 22),
                  Restaurant.new(0, "Domino's Pizza", 34.0077, -118.326, 7, 23),
                  Restaurant.new(1, "Denny's", 34.0466919, -118.2602324, 7, 7),
                  Restaurant.new(2, "Fatburger", 34.0466919, -118.2602324, 10, 2),
                  Restaurant.new(7, "Vim Thai Restaurant", 34.0808571, -118.3320727, 11, 22),
                  Restaurant.new(4, "The Original Pantry Cafe", 34.0466919,-118.2602324, 7, 7),
                  Restaurant.new(6, "Philz Coffee", 34.0466919, -118.2602324, 6, 21),
                  Restaurant.new(9, "Raymond's", 34.0966919, -118.3402324, 10, 19),
                  Restaurant.new(8, "JoJo Pops", 34.0966919, -118.3402324, 8, 23)]

  ratings =  [Rating.new(6, 5),
              Rating.new(2, 4),
              Rating.new(0, 3),
              Rating.new(4, 2),
              Rating.new(1, 2),
              Rating.new(5, 3),
              Rating.new(3, 5),
              Rating.new(7, 4),
              Rating.new(8, 5),
              Rating.new(9, 1)]

  y = Yelp.new(restaurants, ratings)

  # puts y.find(34.0, -118.3, 9, 1, true)
end

describe Yelp do
  let (:restaurants) {
     [Restaurant.new(3, "Big Wangs", 34.0566919, -118.2602324, 7, 23),
      Restaurant.new(5, "Chipotle Mexican Grill", 34.0466919, -118.2602324, 10.5, 22),
      Restaurant.new(0, "Domino's Pizza", 34.0077, -118.326, 7, 23),
      Restaurant.new(1, "Denny's", 34.0466919, -118.2602324, 7, 7),
      Restaurant.new(2, "Fatburger", 34.0466919, -118.2602324, 10, 2),
      Restaurant.new(7, "Vim Thai Restaurant", 34.0808571, -118.3320727, 11, 22),
      Restaurant.new(4, "The Original Pantry Cafe", 34.0466919,-118.2602324, 7, 7),
      Restaurant.new(6, "Philz Coffee", 34.0466919, -118.2602324, 6, 21),
      Restaurant.new(9, "Raymond's", 34.0966919, -118.3402324, 10, 19),
      Restaurant.new(8, "JoJo Pops", 34.0966919, -118.3402324, 8, 23)]
  }
  let (:ratings) {
     [Rating.new(6, 5),
      Rating.new(2, 4),
      Rating.new(0, 3),
      Rating.new(4, 2),
      Rating.new(1, 2),
      Rating.new(5, 3),
      Rating.new(3, 5),
      Rating.new(7, 4),
      Rating.new(8, 5),
      Rating.new(9, 1)]
  }
  let (:y) { Yelp.new(restaurants, ratings) }
  it '#dist_between' do
    # Distance between Statue of Liberty (40.6892°, -74.0444°) and 
    # Eiffel Tower (48.8583°, 2.2945°) = 5837 km
    expect(y.dist_between(40.6892, -74.0444, 48.8583, 2.2945).floor).to eq 5837
  end

  describe '#find' do
    it 'finds restaurants closer than radius to a latitude, longitude' do
      # Restaurants 12 km from 34.0, -118.3, open at . Rating sort: false.
      expect(y.find(34.0, -118.3, 12)).to eq(
       [{:rating=>3, :id=>0, :distance=>2.55, :name=>"Domino's Pizza", :open=>7, :close=>23},
        {:rating=>2, :id=>1, :distance=>6.36, :name=>"Denny's", :open=>7, :close=>7},
        {:rating=>4, :id=>2, :distance=>6.36, :name=>"Fatburger", :open=>10, :close=>2},
        {:rating=>5, :id=>3, :distance=>7.29, :name=>"Big Wangs", :open=>7, :close=>23},
        {:rating=>2, :id=>4, :distance=>6.36, :name=>"The Original Pantry Cafe", :open=>7, :close=>7},
        {:rating=>3, :id=>5, :distance=>6.36, :name=>"Chipotle Mexican Grill", :open=>10.5, :close=>22},
        {:rating=>5, :id=>6, :distance=>6.36, :name=>"Philz Coffee", :open=>6, :close=>21},
        {:rating=>4, :id=>7, :distance=>9.46, :name=>"Vim Thai Restaurant", :open=>11, :close=>22},
        {:rating=>5, :id=>8, :distance=>11.37, :name=>"JoJo Pops", :open=>8, :close=>23},
        {:rating=>1, :id=>9, :distance=>11.37, :name=>"Raymond's", :open=>10, :close=>19}])

      # Restaurants 10 km from 34.0, -118.3, open at . Rating sort: false.
      expect(y.find(34.0, -118.3, 10)).to eq(
       [{:rating=>3, :id=>0, :distance=>2.55, :name=>"Domino's Pizza", :open=>7, :close=>23},
        {:rating=>2, :id=>1, :distance=>6.36, :name=>"Denny's", :open=>7, :close=>7},
        {:rating=>4, :id=>2, :distance=>6.36, :name=>"Fatburger", :open=>10, :close=>2},
        {:rating=>5, :id=>3, :distance=>7.29, :name=>"Big Wangs", :open=>7, :close=>23},
        {:rating=>2, :id=>4, :distance=>6.36, :name=>"The Original Pantry Cafe", :open=>7, :close=>7},
        {:rating=>3, :id=>5, :distance=>6.36, :name=>"Chipotle Mexican Grill", :open=>10.5, :close=>22},
        {:rating=>5, :id=>6, :distance=>6.36, :name=>"Philz Coffee", :open=>6, :close=>21},
        {:rating=>4, :id=>7, :distance=>9.46, :name=>"Vim Thai Restaurant", :open=>11, :close=>22}])
    end

    it 'sorts restaurants in descending order by rating, while distance < radius' do
      # Restaurants 9 km from 34.0, -118.3, open at . Rating sort: true.
      expect(y.find(34.0, -118.3, 9, nil, true)).to eq(
       [{:rating=>5, :id=>6, :distance=>6.36, :name=>"Philz Coffee", :open=>6, :close=>21},
        {:rating=>5, :id=>3, :distance=>7.29, :name=>"Big Wangs", :open=>7, :close=>23},
        {:rating=>4, :id=>2, :distance=>6.36, :name=>"Fatburger", :open=>10, :close=>2},
        {:rating=>3, :id=>0, :distance=>2.55, :name=>"Domino's Pizza", :open=>7, :close=>23},
        {:rating=>3, :id=>5, :distance=>6.36, :name=>"Chipotle Mexican Grill", :open=>10.5, :close=>22},
        {:rating=>2, :id=>4, :distance=>6.36, :name=>"The Original Pantry Cafe", :open=>7, :close=>7},
        {:rating=>2, :id=>1, :distance=>6.36, :name=>"Denny's", :open=>7, :close=>7}])
    end

    it 'shows restaurants open at certain hour, while sorted in descending order by rating, while distance < radius' do
      # Restaurants 9 km from 34.0, -118.3, open at 9. Rating sort: true.
      expect(y.find(34.0, -118.3, 9, 9, true)).to eq(
       [{:rating=>5, :id=>6, :distance=>6.36, :name=>"Philz Coffee", :open=>6, :close=>21},
        {:rating=>5, :id=>3, :distance=>7.29, :name=>"Big Wangs", :open=>7, :close=>23},
        {:rating=>3, :id=>0, :distance=>2.55, :name=>"Domino's Pizza", :open=>7, :close=>23},
        {:rating=>2, :id=>4, :distance=>6.36, :name=>"The Original Pantry Cafe", :open=>7, :close=>7},
        {:rating=>2, :id=>1, :distance=>6.36, :name=>"Denny's", :open=>7, :close=>7}])

      # Restaurants 9 km from 34.0, -118.3, open at 1. Rating sort: true.
      expect(y.find(34.0, -118.3, 9, 1, true)).to eq(
       [{:rating=>4, :id=>2, :distance=>6.36, :name=>"Fatburger", :open=>10, :close=>2},
        {:rating=>2, :id=>4, :distance=>6.36, :name=>"The Original Pantry Cafe", :open=>7, :close=>7},
        {:rating=>2, :id=>1, :distance=>6.36, :name=>"Denny's", :open=>7, :close=>7}])
    end
  end
end

describe Restaurant do
  let (:r) { Restaurant.new(2, "Fatburger", 34.0466919, -118.2602324, 10, 2) }
  it 'sees if restaurant open at certain time. opens: 10 am, closes: 2 am' do
    expect(r.open?(1)).to eq true
    expect(r.open?(3)).to eq false
    expect(r.open?(10)).to eq true
    expect(r.open?(2)).to eq true
  end
end