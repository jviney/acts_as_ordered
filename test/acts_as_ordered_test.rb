require File.join(File.dirname(__FILE__), 'abstract_unit')
require File.join(File.dirname(__FILE__), 'fixtures', 'cartoon')

class ActsAsOrderedTest < Test::Unit::TestCase
  fixtures :cartoons
  
  def wrapped_cartoons(name)
    find_cartoon(name, WrappedCartoon)
  end
  
  def reversed_cartoons(name)
    find_cartoon(name, ReversedCartoon)
  end
  
  def funny_cartoons(name)
    find_cartoon(name, FunnyCartoon)
  end
  
  def silly_cartoons(name)
    find_cartoon(name, SillyCartoon)
  end
  
  def test_normal
    bugs = cartoons(:bugs)
    
    assert_equal bugs, bugs.previous
    assert_equal cartoons(:daffy), bugs.next
    
    # No wrapping
    assert_equal cartoons(:roger), bugs.next.next.next.next.next
    assert_equal bugs, bugs.next.next.next.next.next.next.previous.previous.previous.previous.previous.previous
  end
  
  def test_insert_and_remove
    bugs, daffy = cartoons(:bugs), cartoons(:daffy)
    
    assert_equal daffy, bugs.next
    cat = Cartoon.create(:first_name => 'Cat', :last_name => 'in the Hat')
    assert_equal cat, bugs.next
    assert_equal daffy, bugs.next.next
    
    assert_equal cat, daffy.previous
    cat.destroy
    assert_equal bugs, daffy.previous
  end
  
  def test_desc_order
    bugs = reversed_cartoons(:bugs)
    
    assert_equal bugs, bugs.next
    assert_equal reversed_cartoons(:daffy), bugs.previous
  end
  
  def test_with_wrapping
    elmer = wrapped_cartoons(:elmer)
    
    assert_equal wrapped_cartoons(:roger), elmer.next
    assert_equal wrapped_cartoons(:roger), elmer.previous.previous.previous
    
    assert_equal wrapped_cartoons(:bugs), elmer.next.next
    assert_equal wrapped_cartoons(:bugs), elmer.previous.previous
  end
  
  def test_jump_multiple_no_wrapping
    daffy = cartoons(:daffy)
    
    assert_equal cartoons(:roger), daffy.next(2)
    assert_equal cartoons(:roger), daffy.next(100)
    assert_equal cartoons(:bugs), daffy.previous(10)
  end
  
  def test_jump_multiple_with_wrapping
    roger = wrapped_cartoons(:roger)
    
    assert_equal roger, roger.previous(4)
    assert_equal roger, roger.next(4)
    
    assert_equal wrapped_cartoons(:elmer), roger.previous(9)
    assert_equal wrapped_cartoons(:bugs), roger.next(13)
  end
  
  def test_with_condition
    elmer = silly_cartoons(:elmer)
    
    assert_equal silly_cartoons(:roger), elmer.next
    assert_equal silly_cartoons(:roger), elmer.next(10)
    assert_equal silly_cartoons(:elmer), elmer.previous
    assert_equal silly_cartoons(:elmer), elmer.previous(3)
  end
  
  def test_with_condition_and_wrapping
    bugs = funny_cartoons(:bugs)
    
    assert_equal funny_cartoons(:daffy), bugs.next
    assert_equal funny_cartoons(:elmer), bugs.next.next
    assert_equal funny_cartoons(:bugs), bugs.next.next.next
    
    assert_equal funny_cartoons(:bugs), bugs.next(3)
  end
  
 private
  def find_cartoon(name, klass)
    klass.find(cartoons(name).id)
  end
end
