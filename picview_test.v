module picview

fn test_natural_compare_orders_numbers_numerically() {
	mut files := ['img10.jpg', 'img2.jpg', 'img1.jpg', 'img10a.jpg', 'a.png', 'B.png']
	files.sort_with_compare(natural_compare)
	assert files == ['B.png', 'a.png', 'img1.jpg', 'img2.jpg', 'img10.jpg', 'img10a.jpg']
}

fn test_natural_compare_leading_zeros() {
	p1 := 'img01.jpg'
	p2 := 'img1.jpg'
	p3 := 'img02.jpg'
	p4 := 'img2.jpg'
	assert natural_compare(p1, p2) == 0
	assert natural_compare(p3, p2) == 1
	assert natural_compare(p2, p4) == -1
}
